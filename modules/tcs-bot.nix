{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

let
  domain = "tcsdiscord.bartoostveen.nl";
  name = "tcs-bot";
  port = 6769; # Six seeeeeeeeeeeeeeeeeeeeeeeeeeeven
  dbUser = name;
  dbPassword = "Waarom moet dit, dit is echt super nutteloos aangezien de database niet exposed is, maar hee aan de ene aardling die dit leest, goeie dagschotel!";
  env = {
    REDIS_CONNECTION_STRING = "${name}-redis:6379";
    DATABASE_CONNECTION_STRING = "jdbc:postgresql://${name}-db:5432/${name}";
    DATABASE_USERNAME = dbUser;
    DATABASE_PASSWORD = dbPassword;
    PORT = toString port;
    HOSTNAME = "https://${domain}";
    ENVIRONMENT = "PRODUCTION";
    METRICS_PREFIX = "::1";
  };
  pkg = inputs.tcs-bot.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dockerImage = pkgs.dockerTools.streamLayeredImage {
    inherit name;
    tag = pkg.version;
    contents = [ pkg pkgs.busybox ];
    config.Cmd = [ "/bin/${pkg.pname}" ];
  };
in
{
  virtualisation.oci-containers.containers = {
    ${name} = {
      image = "localhost/${name}:${pkg.version}"; # thank you podman implementation, very cool
      imageStream = dockerImage;
      environment = env;
      environmentFiles = [ config.sops.secrets.tcs-bot-env.path ];
      ports = [ "127.0.0.1:${toString port}:${toString port}" ];
    };
    "${name}-db" = {
      image = "postgres:latest";
      environment = {
        POSTGRES_USER = dbUser;
        POSTGRES_PASSWORD = dbPassword;
        POSTGRES_DB = name;
      };
      volumes = [ "${name}-db-data:/var/lib/postgresql" ];
    };
    "${name}-redis" = {
      image = "valkey/valkey:latest";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${toString port}";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "tcs-bot-auth";
      metrics_path = "/metrics";
      scheme = "https";
      static_configs = [
        {
          targets = [ domain ];
        }
      ];
    }
  ];

  sops.secrets.tcs-bot-env = {
    format = "binary";
    sopsFile = ../secrets/tcs-bot.env.secret;
    restartUnits = [ "podman-tcs-bot.service" ];
  };

  systemd.timers."${name}-db-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; 
      Unit = "${name}-db-backup.service";
    };
  };

  systemd.services."${name}-db-backup" = {
    script = ''
      set -eu
      ${lib.getExe' pkgs.postgresql_18 "pg_dump"} -h $(${lib.getExe pkgs.podman} container inspect -f '{{.NetworkSettings.IPAddress}}' ${name}-db) -d ${name} -U "${dbUser}" > /srv/${name}-$(date +%m-%d-%Y--%H-%M-%S).bak
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    environment.PGPASSWORD = dbPassword;
  };
}
