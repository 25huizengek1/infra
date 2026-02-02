{ config, ... }:

let
  fqdn = "vault.bartoostveen.nl";
in
{
  services.vaultwarden = {
    enable = true;
    domain = fqdn;
    configureNginx = true;
    environmentFile = config.sops.secrets.vaultwarden-env.path;
    config = {
      SIGNUPS_ALLOWED = false;
      ROCKET_LOG = "critical";
      SMTP_HOST = "bartoostveen.nl";
      SMTP_PORT = 25;
      SMTP_SSL = true;
      SMTP_USERNAME = "vaultwarden@bartoostveen.nl";
      SMTP_FROM = "vaultwarden@bartoostveen.nl";
      SMTP_FROM_NAME = "Bart Oostveen's Vault";
    };
  };

  services.nginx.virtualHosts.${fqdn}.enableACME = true;

  sops.secrets.vaultwarden-env = {
    format = "binary";
    owner = "vaultwarden";
    group = "vaultwarden";
    restartUnits = [ "vaultwarden.service" ];
    sopsFile = ../../secrets/vaultwarden.env.secret;
  };
}
