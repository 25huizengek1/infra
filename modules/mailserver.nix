{ pkgs, config, ... }:

let
  domain = "omeduostuurcentenneef.nl";
in
{
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
}
