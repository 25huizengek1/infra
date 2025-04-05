{ pkgs, config, ... }:

let
  domain = (import ../const.nix).domain;
in
rec {
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

    extraFlags = [
      "--web.external-url=https://prometheus.${domain}/"
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

  services.nginx.virtualHosts."prometheus.${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
    };
  };

  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = "127.0.0.1:8086";
    };
    provision.initialSetup.tokenFile = config.sops.influxdb-key.path;
  };

  sops.secrets.influxdb-key = {
    format = "binary";
    sopsFile = ../secrets/influxdb-key.secret;

    owner = "influxdb2";
    group = "influxdb2";
    mode = "0600";
  };

  services.nginx.virtualHosts."influx.${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${services.influxdb2.settings.http-bind-address}";
      proxyWebsockets = true;
    };
  };

  services.telegraf = {
    enable = true;
    extraConfig = {
      outputs.influxdb = {
        urls = [ "http://${services.influxdb2.settings.http-bind-address}" ];
        database = "telegraf";
      };
    };
  };
}
