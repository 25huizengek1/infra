{
  inputs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (types) int str path;

  cfg = config.infra.authentik;
in
{
  imports = [
    inputs.authentik.nixosModules.default
  ];

  options.infra.authentik = {
    enable = mkEnableOption "authentik";
    enablePrometheus = mkEnableOption "Prometheus monitoring of authentik";
    environmentFile = mkOption {
      description = "File outside of nix store containing environment variables such as the email passwords";
      type = path;
    };
    metricsPort = mkOption {
      description = "Prometheus metrics port";
      type = int;
      default = 64151;
    };
    ldapMetricsPort = mkOption {
      description = "Prometheus LDAP metrics port";
      type = int;
      default = 64152;
    };
    domain = mkOption {
      description = "Domain of the authentik server";
      type = str;
      default = "auth.bartoostveen.nl";
    };
    emailHost = mkOption {
      description = "Email host";
      type = str;
      default = "bartoostveen.nl";
    };
    email = mkOption {
      description = "Email of the authentik server";
      type = str;
      default = "auth@bartoostveen.nl";
    };
  };

  config = mkIf cfg.enable {
    services.authentik = {
      enable = true;
      inherit (cfg) environmentFile;
      worker.listenMetrics = "[::1]:${toString cfg.metricsPort}";
      settings = {
        email = {
          host = cfg.emailHost;
          port = 587;
          username = cfg.email;
          use_tls = true;
          use_ssl = false;
          from = cfg.email;
        };
        disable_startup_analytics = true;
        avatars = "initials";
      };
      nginx = {
        enable = true;
        enableACME = true;
        host = cfg.domain;
      };
    };

    services.authentik-ldap = {
      enable = true;
      inherit (cfg) environmentFile;
      listenMetrics = "[::1]:${toString cfg.ldapMetricsPort}";
    };

    services.prometheus = mkIf cfg.enablePrometheus {
      scrapeConfigs = [
        {
          job_name = "authentik";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.metricsPort}" ];
            }
          ];
        }
        {
          job_name = "authentik-ldap";
          static_configs = [
            {
              targets = [ "localhost:${toString cfg.ldapMetricsPort}" ];
            }
          ];
        }
      ];
    };

    users.users.authentik = {
      isSystemUser = true;
      group = "authentik";
    };
    users.groups.authentik = { };

    users.users.authentik-ldap = {
      isSystemUser = true;
      group = "authentik";
    };

    networking.firewall.allowedTCPPorts = [
      3389 # LDAP
      6636 # LDAPS
    ];

    infra.backup.jobs.state.paths = [ config.services.authentik.settings.storage.media.file.path ];
  };
}
