{
  config,
  const,
  lib,
  ...
}:

let
  domain = "bartoostveen.nl";
in
{
  imports = [
    ./passwords.nix
    ./accounts.nix
  ];

  mailserver = {
    enable = true;
    fqdn = domain;
    certificateScheme = "acme-nginx";
    systemName = domain;
    systemDomain = domain;
    domains = [
      domain
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

  sops.secrets."bartoostveen.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../secrets/bartoostveen.nl.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/bartoostveen.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
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
    hostName = "webmail.bartoostveen.nl";
    extraConfig = ''
      $config['imap_host'] = [
        "tls://${domain}" => "${domain}"
      ];
    '';
  };

  services.postfix.config.inet_protocols = "ipv4";
  services.postfix.config.bounce_template_file = "${./bounce-template.cf}";
}
