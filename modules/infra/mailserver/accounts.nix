{ config, ... }:

{
  mailserver.loginAccounts = {
    "bart@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.bart-email-password-encrypted.path;
      aliases = [
        "postmaster@bartoostveen.nl"
        "security@bartoostveen.nl"
        "root@bartoostveen.nl"
        "anubis@bartoostveen.nl"
        "tcsbot@bartoostveen.nl"

        "bart@omeduostuurcentenneef.nl"
        "postmaster@omeduostuurcentenneef.nl"
        "security@omeduostuurcentenneef.nl"
        "spam@omeduostuurcentenneef.nl"

        "postmaster@vitune.app"
        "security@vitune.app"
        "spam@vitune.app"
        "development@vitune.app"
      ];
    };
    "alerts@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.alertmanager-email-password-encrypted.path;
      sendOnly = true;
    };
    "auth@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.authentik-email-password-encrypted.path;
      sendOnly = true;
    };
  };
}
