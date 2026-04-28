{
  pkgs,
  config,
  inputs,
  lib,
  wireguard,
  ...
}:

let
  kumaVHost = "uptime.bartoostveen.nl";
  grafanaVHost = "grafana.vitune.app";

  email = "alerts@${config.mailserver.fqdn}";

  inherit (lib)
    # keep-sorted start
    attrNames
    concatMap
    filterAttrs
    mapAttrsToList
    optionals
    removeAttrs
    # keep-sorted end
    ;

  uptimeKumaMetricsPort = 15108;

  staticConfigsFor =
    {
      host,
      name,
      config' ? inputs.self.nixosConfigurations.${name}.config,
    }:

    let
      hostName = name;
    in
    (
      config'.services.prometheus.exporters
      |> filterAttrs (
        _: e:
        let
          evaluated = builtins.tryEval e;
        in
        evaluated.success && e ? enable && e.enable
      )
      |> attrNames
      |> map (jobName: {
        job_name = "${hostName}-${jobName}";
        static_configs = [
          {
            targets = [ "${host}:${toString config'.services.prometheus.exporters.${jobName}.port}" ];
          }
        ];
      })
    )
    ++ (optionals config'.services.telegraf.enable [
      {
        job_name = "${hostName}-telegraf";
        static_configs = [
          {
            targets = [ "${host}${config'.services.telegraf.extraConfig.outputs.prometheus_client.listen}" ];
          }
        ];
      }
    ])
    ++ (
      if config' ? infra && config'.infra ? extraScrapeConfigs then
        config'.infra.extraScrapeConfigs
        |> mapAttrsToList (
          name: value:
          (removeAttrs value [ "port" ])
          // {
            job_name = "${hostName}-${name}";
            static_configs = [
              {
                targets = [ "${host}:${toString value.port}" ];
              }
            ];
          }
        )
      else
        [ ]
    );
in
{
  imports = [
    inputs.srvos.nixosModules.mixins-telegraf
    inputs.srvos.nixosModules.roles-prometheus
  ];

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = grafanaVHost;
        root_url = "https://${grafanaVHost}";
        protocol = "socket";
      };
      security.secret_key = "$__file{${config.sops.secrets.grafana-secret.path}}";
    };
  };

  services.nginx.virtualHosts.${grafanaVHost} = {
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
      listenAddress = wireguard.primaryIpOf config.networking.hostName;

      configuration = {
        global = {
          smtp_from = "Alerting <${email}>";
          smtp_smarthost = "${config.mailserver.fqdn}:465";
          smtp_auth_username = email;
          smtp_auth_password_file = config.sops.secrets.alertmanager-email-password.path;
        };

        receivers = [
          {
            name = "matrix";
            webhook_configs = [
              {
                url = "http://localhost:4051/!XEut2ilhrx5AFftWSym-qSzEW370UbEYfuxVfOWfY-A";
              }
            ];
          }
          {
            name = "email";
            email_configs = [
              {
                to = "root@bartoostveen.nl";
              }
            ];
          }
        ];

        # give me all destinations pls
        route = {
          receiver = (builtins.elemAt config.services.prometheus.alertmanager.configuration.receivers 0).name;
          routes = map (el: {
            receiver = el.name;
            continue = true;
          }) config.services.prometheus.alertmanager.configuration.receivers;
        };
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
    retentionTime = "180d";

    exporters = {
      nginx.enable = true;
      systemd.enable = true;
      postgres.enable = true;
      node.enable = true;
    };

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
            {
              name = "synapse";
              rules = [
                {
                  expr = "synapse_federation_client_sent_edus_total + 0";
                  labels.type = "EDU";
                  record = "synapse_federation_client_sent";
                }
                {
                  expr = "synapse_federation_client_sent_pdu_destinations_count_total + 0";
                  labels.type = "PDU";
                  record = "synapse_federation_client_sent";
                }
                {
                  expr = "sum(synapse_federation_client_sent_queries) by (job)";
                  labels.type = "Query";
                  record = "synapse_federation_client_sent";
                }
                {
                  expr = "synapse_federation_server_received_edus_total + 0";
                  labels.type = "EDU";
                  record = "synapse_federation_server_received";
                }
                {
                  expr = "synapse_federation_server_received_pdus_total + 0";
                  labels.type = "PDU";
                  record = "synapse_federation_server_received";
                }
                {
                  expr = "sum(synapse_federation_server_received_queries) by (job)";
                  labels.type = "Query";
                  record = "synapse_federation_server_received";
                }
                {
                  expr = "synapse_federation_transaction_queue_pending_edus + 0";
                  labels.type = "EDU";
                  record = "synapse_federation_transaction_queue_pending";
                }
                {
                  expr = "synapse_federation_transaction_queue_pending_pdus + 0";
                  labels.type = "PDU";
                  record = "synapse_federation_transaction_queue_pending";
                }
              ];
            }
          ];
        }
      ))
    ];

    scrapeConfigs = concatMap (
      name:
      staticConfigsFor {
        inherit name;
        host = wireguard.primaryIpOf name;
      }
    ) (builtins.filter (n: inputs.self.nixosConfigurations ? "${n}") (attrNames wireguard.nodes));
  };

  services.nginx.virtualHosts.${config.infra.authentik.domain}.serverAliases = [
    "prometheus.vitune.app"
  ];

  infra.backup.jobs.state = {
    paths = [
      "/var/lib/${config.services.prometheus.stateDir}"
      config.services.grafana.dataDir
    ];
    exclude = [ "/var/lib/${config.services.prometheus.stateDir}/data/wal" ];
  };

  sops.secrets.grafana-secret = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../../../secrets/grafana.secret;
    restartUnits = [ "grafana.service" ];
    owner = "grafana";
    group = "grafana";
  };

  services.uptime-kuma = {
    enable = true;
    settings.HOST = "0.0.0.0";
  };

  services.anubis.instances.uptime-kuma.settings = {
    BIND = "/run/anubis/anubis-uptime-kuma/anubis-uptime-kuma.sock";
    TARGET = "http://${config.services.uptime-kuma.settings.HOST}:${toString config.services.uptime-kuma.settings.PORT}";
    METRICS_BIND = "0.0.0.0:${toString uptimeKumaMetricsPort}";
    METRICS_BIND_NETWORK = "tcp";
  };

  infra.extraScrapeConfigs.uptime-kuma-anubis.port = uptimeKumaMetricsPort;

  services.nginx.virtualHosts.${kumaVHost} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://unix://${config.services.anubis.instances.uptime-kuma.settings.BIND}";
      proxyWebsockets = true;
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/tmp/loki";
      };
      schema_config.configs = [
        {
          from = "2025-09-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config.filesystem.directory = "/tmp/loki/chunks";
    };
  };

  users.groups.alertmanager = { };
  users.users.alertmanager = {
    isSystemUser = true;
    group = "alertmanager";
  };
}
