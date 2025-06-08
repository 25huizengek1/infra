{
  description = "Bart Oostveen's Nix server infra configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    headplane = {
      url = "github:tale/headplane/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt = {
      url = "github:numtide/treefmt-nix";
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
      sops-nix,
      nixos-mailserver,
      headplane,
      treefmt,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      hostname = "bart-server";
      pkgs = import nixpkgs {
        inherit system;
        config.android_sdk.accept_license = true;
        config.allowUnfree = true;
        overlays = [
          (final: super: self.packages.${system})
          (final: super: { nginxStable = super.nginxStable.override { openssl = super.pkgs.libressl; }; })
          headplane.overlays.default
        ];
      };
      const = import ./const.nix;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ system ];
      flake =
        let
          osConfig = nixpkgs.lib.nixosSystem {
            inherit pkgs;
            inherit system;

            specialArgs = {
              inherit inputs;
              inherit hostname;
              inherit const;
            };

            modules = [
              disko.nixosModules.disko
              ./nixos.nix
              nixos-facter-modules.nixosModules.facter
              { config.facter.reportPath = ./facter.json; }
              sops-nix.nixosModules.sops
              nixos-mailserver.nixosModule
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
        treefmt.flakeModule
        ./parts/treefmt.nix
      ];
    };
}
