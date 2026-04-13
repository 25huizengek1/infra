{
  inputs,
  lib,
  config,
  pkgs,
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

  # TODO: remove at next nixos-unstable push
  authentikScope = (inputs.authentik.lib.mkAuthentikScope { inherit pkgs; }).overrideScope (
    _final: prev: {
      generatedGoClient = prev.generatedGoClient.override {
        openapi-generator-cli = pkgs.openapi-generator-cli.overrideAttrs {
          patches = [
            (pkgs.fetchpatch {
              url = "https://github.com/OpenAPITools/openapi-generator/pull/23326.patch";
              hash = "sha256-E1VgtaIW1V+8ch2RpW850fVNl5Iqitjog+0b8DKFgZw=";
            })
          ];
        };
      };
    }
  );
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
      inherit (authentikScope) authentikComponents;
      worker.listenMetrics = "0.0.0.0:${toString cfg.metricsPort}";
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
      listenMetrics = "0.0.0.0:${toString cfg.ldapMetricsPort}";
    };

    infra.extraScrapeConfigs = mkIf cfg.enablePrometheus {
      authentik.port = cfg.metricsPort;
      authentik-ldap.port = cfg.ldapMetricsPort;
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
