{
  config,
  pkgs,
  ...
}:

let
  inherit (import ../const.nix) domain;

  accessKey = "NgalcVZhiekAgzIMFxxj";
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    configureRedis = true;
    hostName = "cloud.${domain}";
    https = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        whiteboard
        ;
    };

    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "sqlite";

      objectstore.s3 = {
        enable = true;
        bucket = "nextcloud";
        autocreate = false;
        key = accessKey;
        secretFile = config.sops.secrets.nextcloud-s3-secret.path;
        hostname = "minio-api.${domain}";
        useSsl = true;
        port = 443;
        usePathStyle = true;
        region = "us-east-1";
      };
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };

  sops.secrets.nextcloud-s3-secret = {
    format = "binary";
    sopsFile = ../secrets/nextcloud-s3-secret.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0600";
  };

  sops.secrets.nextcloud-admin-pass = {
    format = "binary";
    sopsFile = ../secrets/nextcloud-admin-pass.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0600";
  };
}
