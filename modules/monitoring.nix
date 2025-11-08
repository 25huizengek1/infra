{
  pkgs,
  config,
  ...
}:

{
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "grafana.vitune.app";
      root_url = "https://grafana.vitune.app";
      protocol = "socket";
    };
  };

  services.nginx.virtualHosts."grafana.vitune.app" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://unix:${config.services.grafana.settings.server.socket}";
      proxyWebsockets = true;
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];

  services.prometheus = {
    enable = true;

    listenAddress = "127.0.0.1";
    port = 7070;

    alertmanager = {
      enable = true;
      listenAddress = "127.0.0.1";
      configuration = {
        global = {
          smtp_from = "Alerting <alerts@vitune.app>";
          smtp_smarthost = "vitune.app:587";
          smtp_auth_username = "alerts@vitune.app";
          smtp_auth_password_file = config.sops.secrets.alertmanager-email-password.path;
        };
        receivers = [
          {
            name = "admin";
            email_configs = [
              {
                to = "root@bartoostveen.nl";
              }
            ];
            discord_configs = [
              {
                webhook_url_file = config.sops.secrets.alertmanager-discord-webhook.path;
              }
            ];
          }
        ];
        route.receiver = "admin";
      };
    };

    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          {
            targets = [
              "${config.services.prometheus.alertmanager.listenAddress}:${toString config.services.prometheus.alertmanager.port}"
            ];
          }
        ];
      }
    ];

    extraFlags = [
      "--web.external-url=https://prometheus.vitune.app/"
    ];
    globalConfig.scrape_interval = "15s";

    exporters.nginx.enable = true;
    exporters.systemd.enable = true;

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
                  for = "1m";
                  labels.severity = "warning";
                  annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];

    scrapeConfigs = [
      {
        job_name = "nginx";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ];
          }
        ];
      }
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.systemd.port}" ];
          }
        ];
      }
      {
        job_name = "telegraf";
        static_configs = [
          {
            targets = [ "localhost:9273" ];
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts."prometheus.vitune.app" = {
    enableACME = true;
    forceSSL = true;
    listenAddresses = [ "100.64.0.2" ];
    locations."/" = {
      proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
    };
  };

  sops.secrets.alertmanager-discord-webhook = {
    format = "binary";
    mode = "0600";

    sopsFile = ../secrets/alertmanager-discord-webhook.secret;
    restartUnits = [ "alertmanager.service" ];
    owner = "alertmanager";
    group = "alertmanager";
  };

  services.uptime-kuma.enable = true;

  services.nginx.virtualHosts."uptime.vitune.app" = {
    enableACME = true;
    forceSSL = true;
    listenAddresses = [ "100.64.0.2" ];
    locations."/" = {
      proxyPass = "http://${config.services.uptime-kuma.settings.HOST}:${toString config.services.uptime-kuma.settings.PORT}";
    };
  };
}
