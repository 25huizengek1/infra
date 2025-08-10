{
  config,
  const,
  ...
}:

{
  imports = [
    ./passwords.nix
    ./accounts.nix
  ];

  mailserver = {
    enable = true;
    fqdn = const.domain;
    certificateScheme = "acme-nginx";
    systemName = const.domain;
    systemDomain = const.domain;
    domains = [
      const.domain
      "omeduostuurcentenneef.nl"
    ];
    dmarcReporting.enable = true;
    enableManageSieve = true;

    forwards = {
      "bart@${const.domain}" = "25huizengek1@gmail.com";
    };

    stateVersion = 3;
  };

  sops.secrets."omeduostuurcentenneef.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../secrets/omeduostuurcentenneef.nl.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/omeduostuurcentenneef.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  sops.secrets."vitune.app.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../secrets/vitune.app.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/vitune.app.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.${const.domain}";
    extraConfig = ''
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };

  services.postfix.config.inet_protocols = "ipv4";
  services.postfix.config.bounce_template_file = "${./bounce-template.cf}";
}
