{
  sops.secrets.alertmanager-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../secrets/email-passwords/alertmanager.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };

  sops.secrets.alertmanager-email-password = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../secrets/email-passwords/alertmanager.secret;
    restartUnits = [ "alertmanager.service" ];
    owner = "alertmanager";
    group = "alertmanager";
  };

  sops.secrets.discourse-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../secrets/email-passwords/discourse.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };

  sops.secrets.discourse-email-password = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../secrets/email-passwords/discourse.secret;
    restartUnits = [ "discourse.service" ];
    owner = "discourse";
    group = "discourse";
  };

  sops.secrets.bart-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../secrets/email-passwords/bart.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };

  sops.secrets.nextcloud-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../secrets/email-passwords/nextcloud.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };
}
