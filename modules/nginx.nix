{
  config,
  lib,
  pkgs,
  const,
  inputs,
  ...
}:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security@${const.domain}";

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

    virtualHosts."${const.domain}" = {
      forceSSL = true;
      enableACME = true;
      root = ./webroot;

      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };

    virtualHosts."omeduostuurcentenneef.nl" = {
      forceSSL = true;
      enableACME = true;
      root = ./webroot;

      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };

    virtualHosts."search.${const.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/".root = inputs.nuschtos-search.packages.${pkgs.stdenv.system}.mkMultiSearch {
        scopes = [
          {
            name = "copyparty";
            urlPrefix = "https://github.com/9001/copyparty/blob/hovudstraum/";
            modules = [ inputs.copyparty.nixosModules.default ];
            specialArgs = {
              inherit pkgs;
            };
          }
          {
            name = "nix-podman-stacks";
            urlPrefix = "https://github.com/Tarow/nix-podman-stacks/blob/main/";
            optionsJSON =
              let
                # This is the same way nix-podman-stacks generates their option documentation believe it or not...
                eval = inputs.home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  modules = [
                    inputs.nix-podman-stacks.homeModules.all
                    {
                      home.stateVersion = "25.05";
                      home.username = "someuser";
                      home.homeDirectory = "/home/someuser";
                      tarow.podman = {
                        hostIP4Address = "10.10.10.10";
                        hostUid = 1000;
                        externalStorageBaseDir = "/mnt/ext";
                      };
                    }
                  ];
                };
                doc = pkgs.nixosOptionsDoc {
                  inherit (eval) options;
                };
              in
              pkgs.runCommand "options-filtered" { } ''
                ${lib.getExe pkgs.jq} 'to_entries | map(select(.key | startswith("tarow"))) | from_entries' ${doc.optionsJSON}/share/doc/nixos/options.json > $out
              '';
          }
        ];
      };
    };
  };

  # Skip cloudflare when resolving own virtualHosts for some reason
  networking.hosts."127.0.0.1" = builtins.attrNames config.services.nginx.virtualHosts;
}
