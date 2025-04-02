{
  description = "Bart Oostveen's Nix server infra configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    srvos = {
      url = "github:numtide/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      flake-parts,
      nixos-facter-modules,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      hostname = "bart-server";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ (__: _: self.packages.${system}) ];
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ system ];
      flake =
        let
          osConfig = nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit inputs;
              inherit hostname;
            };

            modules = [
              disko.nixosModules.disko
              ./nixos.nix
              nixos-facter-modules.nixosModules.facter
              { config.facter.reportPath = ./facter.json; }
            ];
          };
        in
        {
          inherit inputs;
          inherit pkgs;

          nixosConfigurations.default = osConfig;
          nixosConfigurations.${hostname} = osConfig;
        };
      imports = [

      ];
    };
}
