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
    owner = "alertmanager";
    group = "alertmanager";
    mode = "0600";

    sopsFile = ../../secrets/email-passwords/alertmanager.secret;
    restartUnits = [ "alertmanager.service" ];
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

  sops.secrets.weblate-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../secrets/email-passwords/weblate.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };

  sops.secrets.weblate-email-password = {
    format = "binary";
    sopsFile = ../../secrets/email-passwords/weblate.secret;

    owner = "weblate";
    group = "weblate";
    mode = "0600";
    restartUnits = [ "weblate.service" ];
  };
}
