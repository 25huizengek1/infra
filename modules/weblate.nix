{
  config,
  lib,
  const,
  ...
}:

{
  disabledModules = [ "services/web-apps/weblate.nix" ];
  imports = [ ./patched-nixos/weblate.nix ];

  services.weblate = {
    enable = true;
    localDomain = "weblate.${const.domain}";
    siteTitle = "ViTune Weblate";
    djangoSecretKeyFile = config.sops.secrets.weblate-django-key.path;
    smtp = {
      enable = true;
      host = const.domain;
      from = "Weblate Email Services <weblate@${const.domain}>";
      user = "weblate@${const.domain}";
      passwordFile = config.sops.secrets.weblate-email-password.path;
    };
  };

  services.nginx.virtualHosts.${config.services.weblate.localDomain}.locations."/".proxyPass =
    lib.mkForce "http://unix://${config.services.anubis.instances.weblate.settings.BIND}";
  systemd.services.anubis-weblate.serviceConfig.SupplementaryGroups = [ "weblate" ];
  services.anubis.instances.weblate.settings = {
    TARGET = "unix://${config.services.weblate.unixSocket}";
    METRICS_BIND = "127.0.0.1:16107"; # Prometheus can't scrape Unix sockets
    METRICS_BIND_NETWORK = "tcp";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "weblate-anubis";
      static_configs = [
        {
          targets = [ config.services.anubis.instances.weblate.settings.METRICS_BIND ];
        }
      ];
    }
  ];

  sops.secrets.weblate-django-key = {
    format = "binary";
    sopsFile = ../secrets/weblate-django.secret;

    owner = "weblate";
    group = "weblate";
    mode = "0600";
    restartUnits = [ "weblate.service" ];
  };
}
