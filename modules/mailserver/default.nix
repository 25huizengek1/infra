{
  config,
  const,
  lib,
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
    certificateDomains = lib.lists.remove config.mailserver.fqdn config.mailserver.domains;
    dmarcReporting.enable = true;
    enableManageSieve = true;

    fullTextSearch = {
      enable = true;
      autoIndex = true;
      enforced = "body";
      memoryLimit = 2000; # MiB
      autoIndexExclude = [
        "Trash"
        "\\Junk"
      ];
    };

    useUTF8FolderNames = true;

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
    hostName = "webmail.omeduostuurcentenneef.nl";
    extraConfig = ''
      $config['imap_host'] = [
        "tls://omeduostuurcentenneef.nl" => "omeduostuurcentenneef.nl",
        "tls://${config.mailserver.fqdn}" => "${config.mailserver.fqdn}"
      ];
    '';
  };

  services.postfix.config.inet_protocols = "ipv4";
  services.postfix.config.bounce_template_file = "${./bounce-template.cf}";
}
