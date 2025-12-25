{
  config,
  lib,
  inputs,
  ...
}:

let
  domain = "bartoostveen.nl";
in
{
  imports = [
    inputs.nixos-mailserver.nixosModule

    ./passwords.nix
    ./accounts.nix
  ];

  mailserver = {
    enable = true;

    fqdn = domain;
    systemName = domain;
    systemDomain = domain;
    x509.useACMEHost = domain;

    domains = [
      domain
      "vitune.app"
      "omeduostuurcentenneef.nl"
    ];

    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    systemContact = "postmaster@${domain}";
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

  services.nginx.virtualHosts."${config.mailserver.fqdn}" = {
    serverName = config.mailserver.fqdn;
    serverAliases = lib.lists.remove config.mailserver.fqdn config.mailserver.domains;
    forceSSL = true;
    enableACME = true;
  };

  sops.secrets."bartoostveen.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../secrets/bartoostveen.nl.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/bartoostveen.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  sops.secrets."omeduostuurcentenneef.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../secrets/omeduostuurcentenneef.nl.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/omeduostuurcentenneef.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  sops.secrets."vitune.app.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../secrets/vitune.app.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/vitune.app.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.bartoostveen.nl";
    extraConfig = ''
      $config['smtp_host'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };

  services.postfix.settings.main = {
    inet_protocols = "ipv4";
    bounce_template_file = "${./bounce-template.cf}";
  };
}
