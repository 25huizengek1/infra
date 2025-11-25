{
  inputs,
  lib,
  withSystem,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    mapAttrs
    types
    ;

  inherit (types)
    attrsOf
    submodule
    str
    nullOr
    ;
in
{
  options.flake = {
    nixos = mkOption {
      description = "Set of NixOS configurations for a given host";
      type = attrsOf (submodule {
        options = {
          hostname = mkOption {
            description = "The host name of the NixOS configuration, the attrset key by default";
            type = nullOr str;
            default = null;
          };
          ip = mkOption {
            description = "The IP address to deploy the NixOS configuration to, the hostname by default";
            type = nullOr str;
            default = null;
          };
          username = mkOption {
            description = "The user to deploy from";
            type = str;
            default = "root";
          };
          arch = mkOption {
            description = "The host architecture";
            type = str;
            default = "x86_64-linux";
          };
        };
      });
    };

    extraNixOSConfigurations = mkOption {
      description = "Additional NixOS configurations that should be exported in the `nixosConfigurations` flake output, but not deployed";
      type = attrsOf (submodule {
        options = {
          arch = mkOption {
            description = "The host architecture";
            type = str;
            default = "x86_64-linux";
          };
        };
      });
    };
  };

  config.flake.nixosConfigurations =
    (mapAttrs (
      name:
      {
        arch,
        ...
      }@c:

      let
        hostname = c.hostname or name;
      in
      withSystem arch (
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
    ) config.flake.nixos)
    // mapAttrs (
      name:
      { arch, ... }:
      withSystem arch (
        { pkgs, ... }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit pkgs;
          specialArgs = { inherit inputs; };
          modules = [ ../images/${name}.nix ];
        }
      )
    ) config.flake.extraNixOSConfigurations;
}
