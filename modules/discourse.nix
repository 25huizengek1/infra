{ config, ... }:

let
  domain = "omeduostuurcentenneef.nl";
in
{
  services.discourse = {
    enable = true;
    hostname = "discourse.${domain}";
    admin = {
      username = "admin";
      fullName = "Bart Oostveen";
      email = "bart@${domain}";
      passwordFile = config.sops.secrets.discourse-adm-password.path;
    };
    secretKeyBaseFile = config.sops.secrets.discourse-keybase.path;
    mail.outgoing = {
      serverAddress = domain;
      username = "discourse@${domain}";
      passwordFile = config.sops.secrets.discourse-email-password.path;
      inherit domain;
    };
    mail.contactEmailAddress = "bart@${domain}";
    mail.notificationEmailAddress = "discourse@${domain}";
    database.ignorePostgresqlVersion = true; # PostgreSQL should be backwards-compatible, right? RIGHT?????
  };

  sops.secrets.discourse-adm-password = {
    format = "binary";
    sopsFile = ../secrets/discourse-adm-password.secret;

    owner = "discourse";
    group = "discourse";
    mode = "0660";
    restartUnits = [ "discourse.service" ];
  };

  sops.secrets.discourse-keybase = {
    format = "binary";
    sopsFile = ../secrets/discourse-keybase.secret;

    owner = "discourse";
    group = "discourse";
    mode = "0660";
    restartUnits = [ "discourse.service" ];
  };
}
