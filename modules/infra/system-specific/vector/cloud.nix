{
  pkgs,
  config,
  ...
}:

let
  domain = "vector.bartoostveen.nl";
  fqdn = "cloud.${domain}";
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = fqdn;
    secretFile = config.sops.secrets.vector-nextcloud-secrets.path;
    config = {
      adminpassFile = config.sops.secrets.vector-nextcloud-admin-pass.path;
      dbtype = "pgsql";
    };
    database.createLocally = true;
    configureRedis = true;
    https = true;
    maxUploadSize = "5G";
    settings = {
      allow_local_remote_servers = true;
      mail_smtpmode = "smtp";
      mail_smtpauth = true;
      mail_smtphost = domain;
      mail_smtpport = 465;
      mail_smtpsecure = "ssl";
      mail_smtpname = "cloud@${domain}";
      mail_from_address = "cloud";
      mail_domain = domain;
      defaultapp = "files";
    };
    phpOptions = {
      "opcache.memory_consumption" = "128";
      "opcache.interned_strings_buffer" = "25";
      "opcache.max_accelerated_files" = "4000";
      "opcache.revalidate_freq" = "60";
      "opcache.enable_cli" = "1";
    };
    extraApps = {
      inherit (pkgs.nextcloud33Packages.apps) user_oidc groupfolders;
    };
    extraAppsEnable = true;
  };

  services.nginx.virtualHosts.${fqdn} = {
    forceSSL = true;
    enableACME = true;
  };

  sops.secrets.vector-nextcloud-admin-pass = {
    format = "binary";
    sopsFile = ../../../../secrets/vector-nextcloud-admin-pass.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0660";
  };

  sops.secrets.vector-nextcloud-secrets = {
    format = "binary";
    sopsFile = ../../../../secrets/vector-nextcloud-secrets.json.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0660";
  };
}
