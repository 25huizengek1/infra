{
  config,
  pkgs,
  ...
}:

let
  domain = (import ../const.nix).domain;
in
{
  imports = [ ./passwords.nix ];

  mailserver = {
    enable = true;
    fqdn = domain;
    certificateScheme = "acme-nginx";
    domains = [ domain ];

    dmarcReporting = {
      enable = true;
      inherit domain;
      organizationName = domain;
    };

    loginAccounts = {
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

    forwards = {
      "bart@${domain}" = "25huizengek1@gmail.com";
    };

    stateVersion = 1;
  };

  sops.secrets."vitune.app.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../secrets/vitune.app.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/vitune.app.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.${domain}";
    extraConfig = ''
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };

  services.postfix.config.inet_protocols = "ipv4";

  services.postfix.config.bounce_template_file = "${pkgs.writeText "bounce-template.cf" ''
    failure_template = <<EOF
    Charset: us-ascii
    From: MAILER-DAEMON (Mail Delivery System)
    Subject: Undelivered Mail Returned to Sender
    Postmaster-Subject: Postmaster Copy: Undelivered Mail

    This is the mail system at host $myhostname.

    I'm sorry to have to inform you that your message could not
    be delivered to one or more recipients. It's attached below.

    For further assistance, please send a message to postmaster
    <at> $myhostname

    If you do so, please include this problem report.

                  The mail system
    EOF

    delay_template = <<EOF
    Charset: us-ascii
    From: MAILER-DAEMON (Mail Delivery System)
    Subject: Delayed Mail (still being retried)
    Postmaster-Subject: Postmaster Warning: Delayed Mail

    This is the mail system at host $myhostname.

    ####################################################################
    # THIS IS A WARNING ONLY.  YOU DO NOT NEED TO RESEND YOUR MESSAGE. #
    ####################################################################

    Your message could not be delivered for more than $delay_warning_time_hours hour(s).
    It will be retried until it is $maximal_queue_lifetime_days day(s) old.

                       The mail system
    EOF
  ''}";
}
