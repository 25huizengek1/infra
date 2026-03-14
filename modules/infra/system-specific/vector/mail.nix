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

  roundcubeWithPlugins = pkgs.roundcube.withPlugins (_: [ pkgs.local.roundcube-oidc ]);

  dovecotSeparator = "*";
  dovecotMasterUser = "master";
  dovecotMasterPasswordFile = config.sops.secrets.dovecot-master-password.path;
  dovecotMasterPasswdFile = config.sops.secrets.dovecot-master-passwd.path;
  roundcubeClientSecretFile = config.sops.secrets.roundcube-client-secret.path;
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

  services.dovecot2.extraConfig = ''
    auth_master_user_separator = ${dovecotSeparator}

    passdb {
        driver = static
        args = ${dovecotMasterPasswdFile}
        result_success = continue
        master = yes
    }

    plugin {
      master_user = ${dovecotMasterUser}
    }
  '';

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
    plugins = [ "roundcube_oidc" ];
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

      $config['oidc_imap_master_password'] = file_get_contents("${dovecotMasterPasswordFile}");
      $config['oidc_master_user_separator'] = '${dovecotSeparator}';
      $config['oidc_config_master_user'] = '${dovecotMasterUser}';
      $config['oidc_url'] = 'https://auth.vector.bartoostveen.nl/application/o/webmail/';
      $config['oidc_client'] = 'VZITfwq9s64f2JJp6Rdb7EGPWnYrQqRU0S1ZrUw5';
      $config['oidc_secret'] = file_get_contents("${roundcubeClientSecretFile}");
      $config['oidc_scope'] = 'openid roundcube';
      $config['oidc_field_uid'] = 'webmail_email';
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

  sops.secrets.dovecot-master-password = {
    format = "binary";
    sopsFile = ../../../../secrets/dovecot-master-password.secret;

    restartUnits = [
      "phpfpm-roundcube.service"
      "dovecot.service"
      "postfix.service"
    ];
  };

  sops.secrets.dovecot-master-passwd = {
    format = "binary";
    owner = "dovecot2";
    group = "dovecot2";

    sopsFile = ../../../../secrets/dovecot-master-passwd.secret;

    restartUnits = [
      "phpfpm-roundcube.service"
      "dovecot.service"
      "postfix.service"
    ];
  };

  sops.secrets.roundcube-client-secret = {
    format = "binary";
    sopsFile = ../../../../secrets/roundcube-client.secret;

    restartUnits = [
      "phpfpm-roundcube.service"
      "dovecot.service"
      "postfix.service"
    ];
  };
}
