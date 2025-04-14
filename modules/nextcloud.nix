# TODO: add email server when port 25 is unrestricted
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
    maxUploadSize = "5G";
    database.createLocally = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        whiteboard
        ;
    };

    phpOptions."opcache.interned_strings_buffer" = "23";

    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "pgsql";

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

    settings.enabledPreviewProviders = [
      "OC\\Preview\\BMP"
      "OC\\Preview\\GIF"
      "OC\\Preview\\JPEG"
      "OC\\Preview\\Krita"
      "OC\\Preview\\MarkDown"
      "OC\\Preview\\MP3"
      "OC\\Preview\\OpenDocument"
      "OC\\Preview\\PNG"
      "OC\\Preview\\TXT"
      "OC\\Preview\\XBitmap"
      "OC\\Preview\\HEIC"
    ];
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
    mode = "0660";
  };

  services.prometheus.exporters.nextcloud = {
    enable = true;
    username = "root";
    passwordFile = config.sops.secrets.nextcloud-admin-pass.path;
    listenAddress = "127.0.0.1";
    url = "https://cloud.${domain}";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "nextcloud";
      metrics_path = "/metrics";
      static_configs = [
        {
          targets = [ "${config.services.prometheus.exporters.nextcloud.listenAddress}:${toString config.services.prometheus.exporters.nextcloud.port}" ];
        }
      ];
    }
  ];

  users.users.nextcloud-exporter.extraGroups = [ "nextcloud" ];
}
