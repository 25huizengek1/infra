{ config, ... }:

let
  domain = (import ../../const.nix).domain;
in
{
  mailserver.loginAccounts = {
    "bart@${domain}" = {
      hashedPasswordFile = config.sops.secrets.bart-email-password-encrypted.path;
      aliases = [
        "postmaster@${domain}"
        "security@${domain}"
        "root@${domain}"
        "development@${domain}"
        "anubis@${domain}"
      ];
    };
    "weblate@${domain}" = {
      hashedPasswordFile = config.sops.secrets.weblate-email-password-encrypted.path;
      sendOnly = true;
    };
    "cloud@${domain}" = {
      hashedPasswordFile = config.sops.secrets.nextcloud-email-password-encrypted.path;
      sendOnly = true;
    };
    "alerts@${domain}" = {
      hashedPasswordFile = config.sops.secrets.alertmanager-email-password-encrypted.path;
      sendOnly = true;
    };
  };
}
