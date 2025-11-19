{
  self,
  inputs,
  lib,
  ...
}:

let
  hostnames = [ "bart-server" ];
in
{
  flake.nixosConfigurations = lib.genAttrs hostnames (
    hostname:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (self) pkgs;

      specialArgs = {
        inherit inputs;
        inherit hostname;
      };

      modules = [ ../machines/${hostname}.nix ];
    }
  );
}
