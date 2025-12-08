{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  unixSocket = "/run/copyparty/party.sock";
  group = "anubis";
  username = "adm";
  access.A = username;

  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.infra.copyparty;
in
{
  imports = [
    inputs.copyparty.nixosModules.default
  ];

  options.infra.copyparty = {
    enable = mkEnableOption "copyparty";
    name = mkOption {
      description = "The name of the server";
      type = types.str;
      default = "omeduoparty";
    };
    acme = mkEnableOption "acme";
    hosts = mkOption {
      description = "The domains to run copyparty on";
      type = types.listOf types.str;
      default = [
        "party.vitune.app"
        "fs.omeduostuurcentenneef.nl"
        "files.bartoostveen.nl"
      ];
    };
    volumes = mkOption {
      description = "The volumes that run on this copyparty instance";
      type = types.attrs;
      default = {
        "/" = {
          inherit access;
          path = "/root/private/fs";
        };
        "/m2" = {
          inherit access;
          path = "/root/private/fs/rommel/ut/m2";
        };
        "/share" = {
          access = access // {
            G = "*";
          };
          path = "/root/private/share";
        };
        "/tom" = {
          inherit access;
          path = "/srv/copyparty/tom";
        };
        "/drop" = {
          access = access // {
            wG = "*";
          };
          path = "/srv/copyparty/fs/drop/";
          flags = {
            hardlinkonly = true;
            # adds some extra random stuff so the file is a little more "secret"
            fka = 8;
            # no thumbnails
            dthumb = true;
            # 52 weeks
            lifetime = 60 * 60 * 24 * 7 * 52;
            # no more than 4096 MB over 15 minutes
            maxb = "4096m,600";
            # you do not get to choose the filename
            rand = true;
            # max 512 MB uploads
            sz = "0-512m";
            # always leave a little space
            df = "20g";
            # no XSS please
            nohtml = true;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.copyparty = {
      enable = true;
      package = pkgs.copyparty-unstable;
      settings = {
        inherit (cfg) name;
        i = "unix:770:${unixSocket},127.1";
        no-cfg-cmt-warn = true;
        theme = 2; # Monokai
        ah-alg = "argon2";
        e2dsa = true;
        e2ts = true;
        stats = true;
        spinner = ",padding:0;border-radius:9em;border:.2em solid #444;border-top:.2em solid #fc0";
        shr = "/shares";
        no-tarcmp = true;
        urlform = "get"; # Disable 'send to server log'
        usernames = true; # Username AND password authentication

        # reverse proxy
        # Trust that nginx is configured correctly
        xff-hdr = "x-forwarded-for";
        rproxy = 1;
      };
      accounts.${username}.passwordFile = config.sops.secrets.copyparty-adm-password-enc.path;
      user = group;
      inherit group;
      inherit (cfg) volumes;
    };

    services.nginx.virtualHosts =
      let
        host = {
          enableACME = cfg.acme;
          forceSSL = cfg.acme;
          locations."/" = {
            proxyPass = "http://unix://${config.services.anubis.instances.copyparty.settings.BIND}";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 0;
              proxy_buffering off;
              proxy_request_buffering off;
              proxy_buffers 32 8k;
              proxy_buffer_size 16k;
              proxy_busy_buffers_size 24k;
            '';
          };
        };
      in
      builtins.listToAttrs (map (h: lib.nameValuePair h host) cfg.hosts);

    systemd.sockets.copyparty = {
      before = [ "nginx.service" ];
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = unixSocket;
        SocketUser = group;
        SocketGroup = group;
        SocketMode = "770";
      };
    };

    systemd.services.copyparty.requires = [ "copyparty.socket" ];

    services.anubis.instances.copyparty = {
      botPolicy = {
        bots = [
          {
            name = "telegram";
            user_agent_regex = "TelegramBot (like TwitterBot)";
            action = "ALLOW";
          }
          {
            name = "tailscale";
            remote_addresses = [ "100.64.0.0/16" ];
            action = "ALLOW";
          }
        ];
      };

      settings = {
        BIND = "/run/anubis/anubis-copyparty/anubis-copyparty.sock";
        TARGET = "unix://${unixSocket}";
        METRICS_BIND = "127.0.0.1:16108"; # Prometheus can't scrape Unix sockets
        METRICS_BIND_NETWORK = "tcp";
      };
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "copyparty";
        metrics_path = "/.cpr/metrics/";
        basic_auth = {
          inherit username;
          password_file = config.sops.secrets.copyparty-adm-password.path;
        };
        static_configs = [
          {
            targets = [ "127.0.0.1:3923" ];
          }
        ];
      }
      {
        job_name = "copyparty-anubis";
        static_configs = [
          {
            targets = [ config.services.anubis.instances.copyparty.settings.METRICS_BIND ];
          }
        ];
      }
    ];

    sops.secrets.copyparty-adm-password = {
      format = "binary";
      sopsFile = ../../secrets/copyparty-password.secret;

      owner = "prometheus";
      group = "prometheus";
      mode = "0660";
      restartUnits = [ "prometheus.service" ];
    };

    sops.secrets.copyparty-adm-password-enc = {
      format = "binary";
      sopsFile = ../../secrets/copyparty-password.enc.secret;

      owner = group;
      inherit group;
      mode = "0660";
      restartUnits = [ "copyparty.service" ];
    };

    environment.systemPackages = [ pkgs.copyparty ];
  };
}
