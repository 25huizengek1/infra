{ self, inputs, ... }:
{
  flake =
    let
      hostname = "bart-server";
      osConfig = inputs.nixpkgs.lib.nixosSystem {
        inherit (self) pkgs;

        specialArgs = {
          inherit inputs;
          inherit hostname;
          const = import ../const.nix;
        };

        modules = [
          inputs.disko.nixosModules.disko
          ../machines/bart-server.nix
          inputs.nixos-facter-modules.nixosModules.facter
          { config.facter.reportPath = ../machines/bart-server.json; }
          inputs.sops-nix.nixosModules.sops
          inputs.nixos-mailserver.nixosModule
        ];
      };
    in
    {
      nixosConfigurations.default = osConfig;
      nixosConfigurations.${hostname} = osConfig;
    };
}
