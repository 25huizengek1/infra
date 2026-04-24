{
  config,
  lib,
  inputs,
  ...
}:

let
  domain = "bartoostveen.nl";
  rspamdMetricsPort = 32475;

  inherit (lib) genAttrs' nameValuePair;
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

    dkim.domains = {
      "bartoostveen.nl".selectors.mail.keyFile = config.sops.secrets."bartoostveen.nl.mail.key".path;
      "boostveen.nl".selectors.mail.keyFile = config.sops.secrets."boostveen.nl.mail.key".path;
      "omeduostuurcentenneef.nl".selectors.mail.keyFile =
        config.sops.secrets."omeduostuurcentenneef.nl.mail.key".path;
      "vitune.app".selectors.mail.keyFile = config.sops.secrets."vitune.app.mail.key".path;
    };

    # DKIM/DMARC
    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    systemContact = "postmaster@${domain}";

    hierarchySeparator = "/"; # See: https://doc.dovecot.org/main/core/config/namespaces.html#namespaces

    enableManageSieve = true;
    enableSubmission = true; # Enable StartTLS

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

    stateVersion = 4; # Do not change this line, unless a new version needs to be migrated to
  };

  services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];
  services.prometheus.exporters = {
    dovecot.enable = true;
    postfix.enable = true;
  };
  infra.extraScrapeConfigs.rspamd.port = rspamdMetricsPort;

  services.nginx.virtualHosts."${config.mailserver.fqdn}" = {
    serverName = config.mailserver.fqdn;
    serverAliases = lib.lists.remove config.mailserver.fqdn config.mailserver.domains;
    forceSSL = true;
    enableACME = true;
  };

  sops.secrets =
    genAttrs' [ "bartoostveen.nl" "boostveen.nl" "omeduostuurcentenneef.nl" "vitune.app" ]
      (
        name:
        nameValuePair "${name}.mail.key" {
          format = "binary";
          owner = "rspamd";
          group = "rspamd";
          mode = "0600";

          sopsFile = ../../../../../secrets/dkim/${name}.mail.private.secret;

          restartUnits = [ "rspamd.service" ];
        }
      );

  services.roundcube = {
    enable = true;
    hostName = "webmail.bartoostveen.nl";
    extraConfig = ''
      $config['imap_host'] = "ssl://${config.mailserver.fqdn}:993";
      $config['imap_auth_type'] = 'LOGIN';
      $config['imap_delimiter'] = '/';
      $config['imap_conn_options'] = array(
          'ssl' => array(
              'verify_peer'  => false,
              'verify_peer_name' => false,
          ),
      );

      $config['smtp_host'] = "ssl://${config.mailserver.fqdn}:465";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
      $config['smtp_auth_type'] = 'LOGIN';
      $config['smtp_conn_options'] = array(
          'ssl' => array(
              'verify_peer'  => false,
              'verify_peer_name' => false,
          ),
      );
    '';
  };

  services.postfix.settings.main = {
    inet_protocols = "ipv4, ipv6";
    bounce_template_file = "${./bounce-template.cf}";
  };

  infra.backup.jobs.state.paths = [ config.mailserver.storage.path ];
}
