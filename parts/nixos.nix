{ self, inputs, ... }:

let
  hostname = "bart-server";
in
{
  flake = {
    nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
      inherit (self) pkgs;

      specialArgs = {
        inherit inputs;
        inherit hostname;
      };

      modules = [
        inputs.disko.nixosModules.disko
        ../machines/bart-server.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../machines/bart-server.json; }
        inputs.sops-nix.nixosModules.sops
        inputs.nixos-mailserver.nixosModule
        inputs.copyparty.nixosModules.default
      ];
    };
  };
}
