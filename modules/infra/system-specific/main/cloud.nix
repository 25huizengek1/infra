{
  pkgs,
  config,
  ...
}:

let
  fqdn = "bartoostveen.nl";
  domain = "cloud.${fqdn}";
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = domain;
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "pgsql";
    };
    database.createLocally = true;
    configureRedis = true;
    https = true;
    maxUploadSize = "5G";
    phpOptions = {
      "opcache.memory_consumption" = "128";
      "opcache.interned_strings_buffer" = "25";
      "opcache.max_accelerated_files" = "4000";
      "opcache.revalidate_freq" = "60";
      "opcache.enable_cli" = "1";
    };
    extraApps = {
      inherit (pkgs.nextcloud33Packages.apps) mail;
    };
    extraAppsEnable = true;
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
  };

  infra.backup.jobs.state.paths = [ config.services.nextcloud.home ];

  sops.secrets.nextcloud-admin-pass = {
    format = "binary";
    sopsFile = ../../../../secrets/nextcloud-admin-pass.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0660";
  };
}
