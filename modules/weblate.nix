{ config, ... }:

let
  domain = (import ../const.nix).domain;
in
{
  disabledModules = [ "services/web-apps/weblate.nix" ];
  imports = [ ./patched-nixos/weblate.nix ];

  services.weblate = {
    enable = true;
    localDomain = "weblate.${domain}";
    djangoSecretKeyFile = config.sops.secrets.weblate-django-key.path;
    smtp = {
      enable = true;
      host = domain;
      from = "Weblate Email Services <weblate@${domain}>";
      user = "weblate@${domain}";
      passwordFile = config.sops.secrets.weblate-email-password.path;
    };
  };

  sops.secrets.weblate-django-key = {
    format = "binary";
    sopsFile = ../secrets/weblate-django.secret;

    owner = "weblate";
    group = "weblate";
    mode = "0600";
    restartUnits = [ "weblate.service" ];
  };

  sops.secrets.weblate-email-password = {
    format = "binary";
    sopsFile = ../secrets/weblate-email-password.secret;

    owner = "weblate";
    group = "weblate";
    mode = "0600";
    restartUnits = [ "weblate.service" ];
  };
}
