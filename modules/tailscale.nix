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
      dns.extra_records =
        let
          value = "100.64.0.2";
        in
        [
          {
            type = "A";
            name = "prometheus.${const.domain}";
            inherit value;
          }
          {
            type = "A";
            name = "uptime.${const.domain}";
            inherit value;
          }
        ];
      policy.mode = "database";
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
    agent = {
      enable = false; # TODO
      settings = {
        HEADPLANE_AGENT_DEBUG = true;
        HEADPLANE_AGENT_HOSTNAME = "localhost";
        HEADPLANE_AGENT_TS_SERVER = "https://example.com";
        HEADPLANE_AGENT_TS_AUTHKEY = "xxxxxxxxxxxxxx";
        HEADPLANE_AGENT_HP_SERVER = "https://example.com/admin/dns";
        HEADPLANE_AGENT_HP_AUTHKEY = "xxxxxxxxxxxxxx";
      };
    };
    settings = {
      server = {
        host = "127.0.0.1";
        port = 49686;
        cookie_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
        cookie_secure = true;
      };
      headscale = {
        url = "https://${fqdn}";
        config_path = "${headscaleConfig}";
        config_strict = true;
      };
      # integration.agent.enabled = false;
      integration.proc.enabled = true;
      # Required for some reason, grabbed from docs
      oidc = {
        issuer = "https://oidc.example.com";
        client_id = "headplane";
        disable_api_key_login = true;
        token_endpoint_auth_method = "client_secret_basic";
        redirect_uri = "https://oidc.example.com/admin/oidc/callback";
        headscale_api_key = "xxx";
      };
    };
  };

  services.nginx.virtualHosts."headplane.${const.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.headplane.settings.server.host}:${toString config.services.headplane.settings.server.port}";
      proxyWebsockets = true;
    };
  };

  systemd.services.headplane.environment = {
    "HEADPLANE_LOAD_ENV_OVERRIDES" = "true";
  };
  systemd.services.headplane.serviceConfig.EnvironmentFile = config.sops.secrets.headplane-env.path;
  systemd.services.headscale.serviceConfig.ProtectProc = lib.mkForce "default";

  sops.secrets.headplane-env = {
    format = "binary";
    sopsFile = ../secrets/headplane.env.secret;

    owner = "headscale";
    group = "headscale";
    mode = "0600";
    restartUnits = [ "headscale.service" ];
  };

  services.tailscale.enable = true;
}
