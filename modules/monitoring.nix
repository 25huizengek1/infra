{ pkgs, config, ... }:

# Ideally, multiple servers in a cluster should monitor each other. But why do this when you can also NOT do that

let
  domain = (import ../const.nix).domain;
in
{
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "grafana.${domain}";
      root_url = "https://grafana.${domain}";
      protocol = "socket";
    };
  };

  services.nginx.virtualHosts."grafana.${domain}" = {
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
          smtp_from = "Alerting <alerts@${domain}>";
          smtp_smarthost = "${domain}:587";
          smtp_auth_username = "alerts@${domain}";
          smtp_auth_password_file = config.sops.secrets.alertmanager-email-password.path;
        };
        receivers = [
          {
            name = "admin";
            email_configs = [
              {
                to = "root@${domain}";
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
            targets = [ "${config.services.prometheus.alertmanager.listenAddress}:${toString config.services.prometheus.alertmanager.port}" ];
          }
        ];
      }
    ];

    extraFlags = [
      "--web.external-url=https://prometheus.${domain}/"
    ];
    globalConfig.scrape_interval = "15s";

    exporters.nginx.enable = true;

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
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ];
        }];
      }
    ];
  };

  services.nginx.virtualHosts."prometheus.${domain}" = {
    enableACME = true;
    forceSSL = true;
    listenAddresses = [
      "100.64.0.2" # TODO: refactor
    ];

    locations."/" = {
      proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
    };
  };
}
