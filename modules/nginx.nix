{ lib, pkgs, ... }:

let
  domain = "omeduostuurcentenneef.nl";
in
{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security@${domain}";

  services.nginx = {
    enable = true;

    commonHttpConfig =
      let
        realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
        fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
        cfipv4 = fileToList (
          pkgs.fetchurl {
            url = "https://www.cloudflare.com/ips-v4";
            sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
          }
        );
        cfipv6 = fileToList (
          pkgs.fetchurl {
            url = "https://www.cloudflare.com/ips-v6";
            sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
          }
        );
      in
      ''
        ${realIpsFromList cfipv4}
        ${realIpsFromList cfipv6}
        real_ip_header CF-Connecting-IP;
      '';

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;
      root = ./webroot;

      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };

    virtualHosts."portainer.${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "https://127.0.0.1:9443/";
      };
    };

    virtualHosts."cockpit.${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "https://127.0.0.1:9090/";
        proxyWebsockets = true;
      };
    };

    virtualHosts."jenkins.${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "https://127.0.0.1:8080/";
        proxyWebsockets = true;
      };
    };
  };
}
