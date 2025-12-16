{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  services.nginx.virtualHosts."search.omeduostuurcentenneef.nl" = {
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
          modules = [ inputs.disko.nixosModules.default ];
          name = "disko";
          specialArgs.modulesPath = inputs.nixpkgs + "/nixos/modules";
          urlPrefix = "https://github.com/nix-community/disko/blob/master/";
        }
        {
          name = "headplane";
          urlPrefix = "https://github.com/tale/headplane/blob/main/";
          modules = [ inputs.headplane.nixosModules.headplane ];
          specialArgs = {
            inherit pkgs;
          };
        }
        {
          optionsJSON =
            inputs.home-manager.packages.${pkgs.stdenv.system}.docs-html.passthru.home-manager-options.nixos
            + /share/doc/nixos/options.json;
          name = "Home Manager NixOS";
          urlPrefix = "https://github.com/nix-community/home-manager/tree/master/";
        }
        {
          optionsJSON =
            inputs.home-manager.packages.${pkgs.stdenv.system}.docs-json + /share/doc/home-manager/options.json;
          optionsPrefix = "home-manager.users.<name>";
          name = "Home Manager";
          urlPrefix = "https://github.com/nix-community/home-manager/tree/master/";
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
                  inputs.nix-podman-stacks.homeModules.nps
                  {
                    home.stateVersion = "25.11";
                    home.username = "someuser";
                    home.homeDirectory = "/home/someuser";
                    nps = {
                      hostIP4Address = "10.10.10.10";
                      hostUid = 1000;
                      externalStorageBaseDir = "/mnt/ext";
                    };
                  }
                ];
              };
              doc = pkgs.nixosOptionsDoc {
                inherit (eval) options;
                warningsAreErrors = false; # nix-podman-stacks has some invalid options
              };
            in
            pkgs.runCommand "options-filtered" { } ''
              ${lib.getExe pkgs.jq} 'to_entries | map(select(.key | startswith("nps"))) | from_entries' ${doc.optionsJSON}/share/doc/nixos/options.json > $out
            '';
        }
        {
          optionsJSON =
            (import "${inputs.nixpkgs}/nixos/release.nix" { }).options + /share/doc/nixos/options.json;
          name = "NixOS unstable";
          urlPrefix = "https://github.com/NixOS/nixpkgs/tree/master/";
        }
        {
          modules = [ inputs.nixos-apple-silicon.nixosModules.default ];
          name = "NixOS Apple Silicon";
          urlPrefix = "https://github.com/tpwrules/nixos-apple-silicon/blob/main/";
        }
        {
          name = "plasma-manager";
          urlPrefix = "https://github.com/nix-community/plasma-manager/blob/main/";
          optionsJSON =
            let
              # This is the same way nix-podman-stacks generates their option documentation believe it or not...
              eval = inputs.home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                  inputs.plasma-manager.homeModules.plasma-manager
                  {
                    home.stateVersion = "25.11";
                    home.username = "someuser";
                    home.homeDirectory = "/home/someuser";
                  }
                ];
              };
              doc = pkgs.nixosOptionsDoc {
                inherit (eval) options;
                warningsAreErrors = false; # nix-podman-stacks has some invalid options
              };
            in
            pkgs.runCommand "options-filtered" { } ''
              ${lib.getExe pkgs.jq} 'to_entries | map(select(.key | startswith("programs.plasma"))) | from_entries' ${doc.optionsJSON}/share/doc/nixos/options.json > $out
            '';
        }
        {
          modules = [
            inputs.nixos-mailserver.nixosModules.default
            # based on https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/blob/290a995de5c3d3f08468fa548f0d55ab2efc7b6b/flake.nix#L61-73
            {
              mailserver = {
                fqdn = "mx.example.com";
                domains = [ "example.com" ];
                dmarcReporting = {
                  organizationName = "Example Corp";
                  domain = "example.com";
                };
              };
            }
          ];
          name = "simple-nixos-mailserver";
          urlPrefix = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/blob/master/";
        }
        {
          modules = [ inputs.sops-nix.nixosModules.default ];
          name = "sops-nix";
          urlPrefix = "https://github.com/Mic92/sops-nix/blob/master/";
        }
      ];
    };
  };
}
