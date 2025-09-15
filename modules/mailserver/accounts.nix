{ config, ... }:

let
  domain = (import ../../const.nix).domain;
in
{
  mailserver = {
    loginAccounts = {
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
          "spam@omeduostuurcentenneef.nl"
        ];
      };
      # Because fuck you that's why
      "bart@omeduostuurcentenneef.nl" = {
        hashedPasswordFile = config.sops.secrets.bart-email-password-encrypted.path;
        aliases = config.mailserver.loginAccounts."bart@${domain}".aliases;
      };
      "cloud@${domain}" = {
        hashedPasswordFile = config.sops.secrets.nextcloud-email-password-encrypted.path;
        sendOnly = true;
      };
      "alerts@${domain}" = {
        hashedPasswordFile = config.sops.secrets.alertmanager-email-password-encrypted.path;
        sendOnly = true;
      };
      "discourse@omeduostuurcentenneef.nl" = {
        hashedPasswordFile = config.sops.secrets.discourse-email-password-encrypted.path;
        sendOnly = true;
      };
    };

    forwards = {
      "bart@${domain}" = "bart@omeduostuurcentenneef.nl";
    };
  };
}
