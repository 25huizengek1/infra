{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  reverseString =
    string: builtins.concatStringsSep "" (lib.flatten (lib.reverseList (builtins.split "" string)));
in
{
  imports = [
    inputs.srvos.nixosModules.mixins-nginx
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security" + "@" + (reverseString "feennetnecruutsoudemo") + ".nl";

  services.nginx = {
    enable = true;

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
    statusPage = true;

    clientMaxBodySize = "128m";

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    defaultListenAddresses = [
      "0.0.0.0"
      "[::0]"
      "100.64.0.2"
    ];
  };

  # Skip cloudflare when resolving own virtualHosts for some reason
  networking.hosts."127.0.0.1" = builtins.attrNames config.services.nginx.virtualHosts;
}
