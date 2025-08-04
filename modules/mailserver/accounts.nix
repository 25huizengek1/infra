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
        "seafile@${domain}"
        "bart@omeduostuurcentenneef.nl"
        "postmaster@omeduostuurcentenneef.nl"
        "security@omeduostuurcentenneef.nl"
      ];
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
