{
  config,
  pkgs,
  const,
  ...
}:

let
  accessKey = "NgalcVZhiekAgzIMFxxj";
in
{
  environment.systemPackages = with pkgs; [
    ffmpeg
  ];

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    configureRedis = true;
    hostName = "cloud.${const.domain}";
    https = true;
    maxUploadSize = "5G";
    database.createLocally = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        forms
        impersonate
        mail
        polls
        previewgenerator
        ;
      notify_push = pkgs.nextcloud-notify_push.app;
    };

    phpOptions = {
      "opcache.memory_consumption" = "128";
      "opcache.interned_strings_buffer" = "25";
      "opcache.max_accelerated_files" = "4000";
      "opcache.revalidate_freq" = "60";
      "opcache.enable_cli" = "1";
    };

    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "pgsql";

      objectstore.s3 = {
        enable = true;
        bucket = "nextcloud";
        verify_bucket_exists = false;
        key = accessKey;
        secretFile = config.sops.secrets.nextcloud-s3-secret.path;
        hostname = "minio-api.${const.domain}";
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
      "OC\\Preview\\MP4"
      "OC\\Preview\\OpenDocument"
      "OC\\Preview\\PNG"
      "OC\\Preview\\TXT"
      "OC\\Preview\\XBitmap"
      "OC\\Preview\\HEIC"
    ];

    settings.trusted_domains = [ "cloud.koensjoligedomeintje.nl" ];

    notify_push = {
      enable = true;
      dbtype = "pgsql";
      bendDomainToLocalhost = true;
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };

  services.nginx.virtualHosts."cloud.koensjoligedomeintje.nl" = {
    inherit (config.services.nginx.virtualHosts.${config.services.nextcloud.hostName})
      forceSSL
      enableACME
      locations
      root
      extraConfig
      ;
  };

  sops.secrets.nextcloud-s3-secret = {
    format = "binary";
    sopsFile = ../secrets/nextcloud-s3-secret.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0600";
    restartUnits = [ "nextcloud.service" ];
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
    url = "https://cloud.${const.domain}";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "nextcloud";
      metrics_path = "/metrics";
      static_configs = [
        {
          targets = [
            "${config.services.prometheus.exporters.nextcloud.listenAddress}:${toString config.services.prometheus.exporters.nextcloud.port}"
          ];
        }
      ];
    }
  ];

  users.users.nextcloud-exporter.extraGroups = [ "nextcloud" ];
}
