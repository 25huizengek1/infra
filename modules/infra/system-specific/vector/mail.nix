{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (import "${inputs.nixos-mailserver}/mail-server/common.nix" { inherit config pkgs lib; })
    appendLdapBindPwd
    ;
  domain = "vector.bartoostveen.nl";

  ldapBase = "dc=ldap,dc=vector,dc=bartoostveen,dc=nl";
  ldapPasswordFile = config.sops.secrets.ldap-bind-password.path;
  ldapHost = "${domain}:3389";
  ldapBindDN = "cn=ldapservice,ou=users,${ldapBase}";
  ldapGroupsFile = "/run/postfix/ldap-groups.cf";
  ldapMapFile = pkgs.writeText "ldap-groups.cf" ''
    server_host = ${ldapHost}
    version = 3
    start_tls = yes

    search_base = ou=groups,${ldapBase}
    query_filter = (&(objectClass=group)(sAMAccountName=%u)(!(|(mailBindIgnore=TRUE)(mailBindIgnore=true))))
    special_result_attribute = member
    leaf_result_attribute = cn
    result_format = %s@${domain}

    bind = yes
    bind_dn = ${ldapBindDN}
  '';
  writeLdapMapFile = appendLdapBindPwd {
    name = "ldap-groups";
    file = ldapMapFile;
    prefix = "bind_pw = ";
    passwordFile = ldapPasswordFile;
    destination = ldapGroupsFile;
  };

  roundcubeWithPlugins = pkgs.roundcube.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/share/roundcube/plugins
      cp -r ${
        pkgs.fetchFromGitHub {
          owner = "pulsejet";
          repo = "roundcube-oidc";
          tag = "1.2.13";
          sha256 = "sha256-sFarGyC3NwjQs+NLPJNt9TbtwQcBXAowe7lW4GYO+wY==";
        }
      } $out/share/roundcube/plugins/oidc_login
    '';
  });
in
{
  imports = [
    inputs.nixos-mailserver.nixosModule
  ];

  mailserver = {
    enable = true;

    fqdn = domain;
    systemName = domain;
    systemDomain = domain;
    x509.useACMEHost = domain;
    domains = [ domain ];

    # DKIM/DMARC
    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    systemContact = "postmaster@${domain}";

    hierarchySeparator = "/"; # See: https://doc.dovecot.org/main/core/config/namespaces.html#namespaces

    enableManageSieve = true;
    enableImap = true;
    enableSubmission = true; # Enable StartTLS

    ldap = {
      enable = true;
      uris = [ "ldap://${ldapHost}" ];
      dovecot = {
        userFilter = "(&(objectClass=user)(sAMAccountName=%n))";
        passFilter = "(&(objectClass=user)(sAMAccountName=%n))";
        userAttrs = ''
          =home=/var/vmail/ldap/%{ldap:sAMAccountName}
        '';
      };
      postfix = {
        filter = "(&(objectClass=user)(sAMAccountName=%u))";
        uidAttribute = "sAMAccountName";
      };
      bind = {
        dn = ldapBindDN;
        passwordFile = ldapPasswordFile;
      };
      searchBase = "ou=users,${ldapBase}";
      searchScope = "sub";
    };

    forwards = {
      "postmaster@vector.bartoostveen.nl" = "postmaster@bartoostveen.nl";
    };

    useUTF8FolderNames = true;

    stateVersion = 3; # Do not change this line, unless a new version needs to be migrated to
  };

  services.postfix.settings.main = {
    inet_protocols = "ipv4";
    bounce_template_file = "${./bounce-template.cf}";
    virtual_alias_maps = [ "ldap:${ldapGroupsFile}" ];
  };

  systemd.services.postfix.preStart = ''
    ${writeLdapMapFile}
  '';

  services.roundcube = {
    enable = true;
    package = roundcubeWithPlugins;
    hostName = "webmail.${domain}";
    extraConfig = ''
      // always, except when replying to plain text message
      $config['htmleditor'] = 4;

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
      $config['smtp_auth_type'] = 'LOGIN';
      $config['smtp_conn_options'] = array(
          'ssl' => array(
              'verify_peer'  => false,
              'verify_peer_name' => false,
          ),
      );

      $config['ldap_public']['public'] = array(
          'name'              => 'Alle addressen',
          'hosts'             => array('ldap://${ldapHost}'),
          'writable'          => false,
          'ldap_version'      => 3,
          'user_specific'     => false,
          'base_dn'           => 'ou=users,${ldapBase}',
          'bind_dn'           => '${ldapBindDN}',
          'bind_pass'         => file_get_contents("${ldapPasswordFile}"),
          'filter'            => '(objectClass=inetOrgPerson)'
      );
    '';
  };

  sops.secrets."vector.bartoostveen.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../../secrets/vector.bartoostveen.nl.mail.key.secret;

    path = "${config.mailserver.dkimKeyDirectory}/vector.bartoostveen.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
  };
}
