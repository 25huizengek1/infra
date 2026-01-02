{ inputs, config, ... }:

let
  fqdn = "bartoostveen.nl";

  metrics-port = 64151;
  ldap-metrics-port = 64152;
in
{
  imports = [
    inputs.authentik.nixosModules.default
  ];

  services.authentik = {
    enable = true;
    environmentFile = config.sops.secrets.authentik-env.path;
    worker.listenMetrics = "[::1]:${toString metrics-port}";
    settings = {
      email = {
        host = fqdn;
        port = 587;
        username = "auth@${fqdn}";
        use_tls = true;
        use_ssl = false;
        from = "auth@${fqdn}";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
    nginx = {
      enable = true;
      enableACME = true;
      host = "auth.${fqdn}";
    };
  };

  services.authentik-ldap = {
    enable = true;
    environmentFile = config.sops.secrets.authentik-env.path;
    listenMetrics = "[::1]:${toString ldap-metrics-port}";
  };

  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "authentik";
        static_configs = [
          {
            targets = [ "localhost:${toString metrics-port}" ];
          }
        ];
      }
      {
        job_name = "authentik-ldap";
        static_configs = [
          {
            targets = [ "localhost:${toString ldap-metrics-port}" ];
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

  sops.secrets.authentik-env = {
    format = "binary";
    sopsFile = ../../secrets/authentik.env.secret;

    owner = "authentik";
    group = "authentik";
    mode = "0660";
    restartUnits = [
      "authentik.service"
      "authentik-worker.service"
      "authentik-ldap.service"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    3389 # LDAP
    6636 # LDAPS
  ];

  # services.dovecot2.extraConfig = "TODO";
}
