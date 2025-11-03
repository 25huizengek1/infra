{
  config,
  pkgs,
  inputs,
  lib,
  const,
  ...
}:

let
  vhost = "headscale";
  fqdn = "${vhost}.${const.domain}";

  format = pkgs.formats.yaml { };

  settings = lib.recursiveUpdate config.services.headscale.settings {
    acme_email = "/dev/null";
    tls_cert_path = "/dev/null";
    tls_key_path = "/dev/null";
    policy.path = "/dev/null";
    oidc.client_secret_path = "/dev/null";
  };
  headscaleConfig = format.generate "headscale.yml" settings;
in
{
  imports = [
    inputs.headplane.nixosModules.headplane
  ];

  services.headscale = {
    enable = true;
    port = 41916;
    settings = {
      server_url = "https://${fqdn}:443";
      dns.base_domain = "tailnet.${const.domain}";
      dns.nameservers.global = [
        "8.8.8.8"
        "8.8.4.4"
        "1.1.1.1"
        "1.0.0.1"
      ];
      dns.extra_records = lib.mapAttrsToList (name: _value: {
        type = "A";
        inherit name;
        value = "100.64.0.2";
      }) (removeAttrs config.services.nginx.virtualHosts [ fqdn ]);
      policy.mode = "database";
      derp = {
        auto_update_enabled = true;
        paths = [
          # TODO: don't hard-code this
          (pkgs.writeText "derpmap.yml" ''
            regions:
              900:
                nodes:
                - canport80: true
                  hostname: derp.omeduostuurcentenneef.nl
                  ipv4: 78.46.150.107
                  ipv6: 2a01:4f8:c2c:2f66::1
                  name: '1'
                  regionid: 900
                regioncode: omeduoderp
                regionid: 900
          '')
        ];
      };
    };
  };

  services.nginx.virtualHosts."${fqdn}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.headscale.address}:${toString config.services.headscale.port}";
      proxyWebsockets = true;
    };
  };

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 49686;
        cookie_secure = true;
        cookie_secret_path = config.sops.secrets.headplane-cookie.path;
      };
      headscale = {
        url = "https://${fqdn}";
        config_path = "${headscaleConfig}";
        config_strict = true;
      };
      integration.agent.enabled = false; # TODO
      integration.agent.pre_authkey_path = "${pkgs.writeText "headscale-pre-auth-key" ''''}"; # WHY WHY WHY WHY
      integration.proc.enabled = true;
      # Required for some reason, grabbed from docs
      oidc = {
        issuer = "https://oidc.example.com";
        client_id = "headplane";
        disable_api_key_login = false;
        token_endpoint_auth_method = "client_secret_basic";
        redirect_uri = "https://oidc.example.com/admin/oidc/callback";
        headscale_api_key_path = "${pkgs.writeText "headscale-api-key" ''''}"; # WHY WHY WHY WHY
      };
    };
  };

  services.tailscale.derper = {
    enable = true;
    domain = "derp.omeduostuurcentenneef.nl";
    verifyClients = true;
  };

  services.nginx.virtualHosts.${config.services.tailscale.derper.domain}.enableACME = true;

  services.nginx.virtualHosts."headplane.${const.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.headplane.settings.server.host}:${toString config.services.headplane.settings.server.port}";
      proxyWebsockets = true;
    };
  };

  sops.secrets.headplane-cookie = {
    format = "binary";
    sopsFile = ../secrets/headplane_cookie.secret;

    owner = "headscale";
    group = "headscale";
    mode = "0600";
    restartUnits = [ "headplane.service" ];
  };

  services.tailscale.enable = true;
}
