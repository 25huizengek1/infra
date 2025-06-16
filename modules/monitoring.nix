{
  pkgs,
  config,
  const,
  ...
}:

# Ideally, multiple servers in a cluster should monitor each other. But why do this when you can also NOT do that

{
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "grafana.${const.domain}";
      root_url = "https://grafana.${const.domain}";
      protocol = "socket";
    };
  };

  services.nginx.virtualHosts."grafana.${const.domain}" = {
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
          smtp_from = "Alerting <alerts@${const.domain}>";
          smtp_smarthost = "${const.domain}:587";
          smtp_auth_username = "alerts@${const.domain}";
          smtp_auth_password_file = config.sops.secrets.alertmanager-email-password.path;
        };
        receivers = [
          {
            name = "admin";
            email_configs = [
              {
                to = "root@${const.domain}";
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
      "--web.external-url=https://prometheus.${const.domain}/"
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
    ];
  };

  services.nginx.virtualHosts."prometheus.${const.domain}" = {
    enableACME = true;
    forceSSL = true;
    listenAddresses = [
      "100.64.0.2" # TODO: refactor
    ];

    locations."/" = {
      proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
    };
  };

  sops.secrets.alertmanager-discord-webhook = {
    format = "binary";
    owner = "alertmanager";
    group = "alertmanager";
    mode = "0600";

    sopsFile = ../secrets/alertmanager-discord-webhook.secret;
    restartUnits = [ "alertmanager.service" ];
  };
}
