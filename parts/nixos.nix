{
  inputs,
  lib,
  withSystem,
  ...
}:

let
  hostnames = [ "bart-server" ];
in
{
  flake.nixosConfigurations = lib.genAttrs hostnames (
    hostname:
    withSystem "x86_64-linux" (
      { pkgs, ... }:

      inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs;

        specialArgs = { inherit inputs; };

        modules = [
          { networking.hostName = hostname; }
          ../machines/${hostname}.nix
        ];
      }
    )
  );
}
