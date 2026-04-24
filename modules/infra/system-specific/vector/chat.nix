{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (pkgs.callPackage ../../matrix/lib.nix { }) mkAutokumaMonitor;

  upstream = "bartoostveen.nl"; # this home server does not provide federation, but we will federate with the administrator, so we call this 'upstream'

  domain = "popkoorklankkleur.nl";
  fqdn = "chat.${domain}";

  staticJSONResponse = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';

  clientWellKnown = {
    "m.homeserver".base_url = "https://${fqdn}";
    "io.element.e2ee" = {
      default = false;
      force_disable = true;
    };
  };
  clientConfig = staticJSONResponse clientWellKnown;

  serverWellKnown."m.server" = "${fqdn}:443";
  serverConfig = staticJSONResponse serverWellKnown;

  supportWellKnown.contacts = [
    {
      role = "m.role.admin";
      email_address = "akadmin@${domain}";
      matrix_id = "@akadmin:${domain}";
    }
  ];
  supportConfig = staticJSONResponse supportWellKnown;

  user = "matrix-synapse";
  federationPort = 8448;
  metricsPort = 8449;

  inherit (lib) mkDefault genAttrs;
in
{
  services.matrix-synapse = {
    enable = true;
    extras = [
      "postgres"
      "url-preview"
      "oidc"
    ];
    enableRegistrationScript = true;
    configureRedisLocally = true;
    extraConfigFiles = [ config.sops.secrets.vector-synapse-secrets.path ];
    settings = {
      server_name = domain;
      public_baseurl = "https://${fqdn}";
      enable_metrics = true;
      listeners = [
        {
          port = federationPort;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
        {
          port = metricsPort;
          type = "metrics";
          bind_addresses = [ "::" ];
          tls = false;
          x_forwarded = false;
        }
      ];
      federation_domain_whitelist = [ upstream ];
      federation_whitelist_endpoint_enabled = false;
      auto_accept_invites = {
        enabled = true;
        only_from_local_users = true;
      };
      auto_join_rooms = [ "#space:${domain}" ];
      allow_reuse_of_user_ids = true;
      templates.custom_template_directory = ./synapse-template-overrides;
    };
  };

  services.nginx.virtualHosts = {
    ${domain}.locations = {
      "= /.well-known/matrix/server".extraConfig = serverConfig;
      "= /.well-known/matrix/client".extraConfig = clientConfig;
      "= /.well-known/matrix/support".extraConfig = supportConfig;
    };
    ${fqdn} = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/".root = "${pkgs.element-web.override {
          conf = {
            default_server_config = clientWellKnown;
            default_federate = false;
            room_directory.servers = [
              upstream
              domain
            ];
            brand = "Popkoor KlankKleur chat";
            permalink_prefix = "https://${fqdn}";
            disable_guests = true;
            force_verification = false; # We do not want to force users to set up E2EE; just not the target (demographic)
            logout_redirect_url = "https://auth.popkoorklankkleur.nl/application/o/chat/end-session/";
            sso_redirect_options.immediate = true;
            terms_and_conditions_links = [
              {
                text = "Privacybeleid";
                url = "https://${domain}/privacybeleid";
              }
            ];
          };
        }}";
        "/_synapse/metrics".extraConfig = "return 404;";
      }
      // genAttrs [ "/_matrix" "/_synapse" ] (_: {
        proxyPass = "http://[::1]:${toString federationPort}";
        rateLimit = false;
      });
    };
    "admin.${fqdn}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".root = "${pkgs.local.ketesa.override {
        conf = {
          restrictBaseUrl = "https://${fqdn}";
          wellKnownDiscovery = true;
        };
      }}";
    };
  };

  services.postgresql = {
    enable = mkDefault true;
    ensureDatabases = [ user ];
    ensureUsers = [
      {
        name = user;
        ensureDBOwnership = true;
      }
    ];
  };

  infra = {
    autokuma.instances.local = mkAutokumaMonitor domain;
    backup.jobs.state.paths = [ config.services.matrix-synapse.dataDir ];
    extraScrapeConfigs.synapse = {
      port = metricsPort;
      metrics_path = "/_synapse/metrics";
    };
  };

  sops.secrets.vector-synapse-secrets = {
    format = "binary";
    owner = user;
    group = user;
    mode = "440";
    sopsFile = ../../../../secrets/vector-synapse-secrets.yaml.secret;
    restartUnits = [ "matrix-synapse.service" ];
  };
}
