{
  sops.secrets.alertmanager-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/alertmanager.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.authentik-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/auth.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.bart-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/bart.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot2.service"
    ];
  };
}
