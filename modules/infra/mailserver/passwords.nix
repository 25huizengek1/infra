{
  sops.secrets.alertmanager-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../secrets/email-passwords/alertmanager.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };

  users.groups.alertmanager = { };
  users.users.alertmanager = {
    isSystemUser = true;
    group = "alertmanager";
  };
  sops.secrets.alertmanager-email-password = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../../secrets/email-passwords/alertmanager.secret;
    restartUnits = [ "alertmanager.service" ];
    owner = "alertmanager";
    group = "alertmanager";
  };

  sops.secrets.bart-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../secrets/email-passwords/bart.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };
}
