{ pkgs, config, ... }:

{
  services.grafana = {
    enable = true;
    settings.server =
      let
        domain = "grafana.omeduostuurcentenneef.nl";
      in
      {
        inherit domain;
        root_url = "https://${domain}";
        protocol = "socket";
      };
  };

  services.prometheus = {
    enable = true;
    port = 7070;
    extraFlags = [
      "--web.external-url=https://prometheus.omeduostuurcentenneef.nl/"
    ];
    globalConfig.scrape_interval = "15s";

    ruleFiles = [
      (pkgs.writeText "up.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "up";
              rules = [
                {
                  alert = "NotUp";
                  expr = ''
                    up == 0
                  '';
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];
  };

  services.influxdb2 = {
    enable = true;
    provision.initialSetup.tokenFile = config.sops.influxdb-key.path;
  };

  sops.secrets.influxdb-key = {
    format = "binary";
    sopsFile = ../secrets/influxdb-key.secret;
    
    owner = "influxdb2";
    group = "influxdb2";
    mode = "0600";
  };

  services.telegraf = {
    enable = true;
    extraConfig = {
      outputs.influxdb = {
        urls = [ "http://localhost:8086" ];
        database = "telegraf";
      };
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];
}
