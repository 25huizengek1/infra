{
  pkgs,
  lib,
  config,
  ...
}:

let
  domain = "omeduostuurcentenneef.nl";
in
rec {
  mailserver = {
    enable = true;
    fqdn = "mail.${domain}";
    certificateScheme = "acme-nginx";
    domains = [ domain ];

    loginAccounts = {
      "bart@${domain}" = {
        hashedPasswordFile = "${pkgs.writeText "bart.passwd" "$2b$05$gRrfXQkzrZzx1w.ouJKeoOLMt7UFTQR8fBgZ/rjOy2HcMYY8XgV2K"}";
        aliases = [
          "postmaster@${domain}"
          "security@${domain}"
        ];
      };
    };
  };

  sops.secrets."${domain}.mail.key" = {
    format = "binary";
    owner = "opendkim";
    group = "opendkim";
    mode = "0600";

    sopsFile = ../secrets/mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/omeduostuurcentenneef.nl.mail.key";
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

  services.nginx.virtualHosts."webmail.${domain}".forceSSL = false;

  services.radicale =
    with lib;
    let
      mailAccounts = mailserver.loginAccounts;
      htpasswd = pkgs.writeText "radicale.users" (
        concatStrings (
          flip mapAttrsToList mailAccounts (mail: user: mail + ":" + builtins.readFile user.hashedPasswordFile + "\n")
        )
      );
    in
    {
      enable = true;
      config = ''
        [auth]
        type = htpasswd
        htpasswd_filename = ${htpasswd}
        htpasswd_encryption = bcrypt
      '';
    };

  services.nginx.virtualHosts."calendar.${domain}" = {
    forceSSL = false;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:5232/";
      extraConfig = ''
        proxy_set_header  X-Script-Name /;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass_header Authorization;
      '';
    };
  };
}
