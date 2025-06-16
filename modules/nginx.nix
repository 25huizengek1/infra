{
  lib,
  pkgs,
  const,
  ...
}:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security@${const.domain}";

  security.pam.services.nginx.setEnvironment = false;
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "shadow" ];

  services.nginx = {
    enable = true;
    additionalModules = [ pkgs.nginxModules.pam ];

    commonHttpConfig =
      let
        realIps =
          file:
          lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};") (
            lib.strings.splitString "\n" (builtins.readFile file)
          );
        v4 = pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v4";
          hash = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
        };
        v6 = pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v6";
          hash = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
        };
      in
      ''
        ${realIps v4}
        ${realIps v6}
        real_ip_header CF-Connecting-IP;
      '';

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    statusPage = true;

    clientMaxBodySize = "128m";

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    virtualHosts."${const.domain}" = {
      forceSSL = true;
      enableACME = true;
      root = ./webroot;

      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };
  };
}
