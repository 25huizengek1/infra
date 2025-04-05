{
  config,
  ...
}:

let
  domain = (import ../const.nix).domain;
in
{
  mailserver = {
    enable = true;
    fqdn = "mail.${domain}";
    certificateScheme = "acme-nginx";
    domains = [ domain ];

    loginAccounts = {
      "bart@${domain}" = {
        hashedPasswordFile = config.sops.secrets.bart-email-password.path;
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

  sops.secrets.bart-email-password = {
    format = "binary";
    sopsFile = ../secrets/bart-email-password.secret;
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
}
