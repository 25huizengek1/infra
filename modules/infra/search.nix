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
          name = "headplane";
          urlPrefix = "https://github.com/tale/headplane/blob/main/";
          modules = [ inputs.headplane.nixosModules.headplane ];
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
                  inputs.nix-podman-stacks.homeModules.nps
                  {
                    home.stateVersion = "25.05";
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
                    home.stateVersion = "25.05";
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
      ];
    };
  };
}
