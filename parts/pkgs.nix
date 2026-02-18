{
  self,
  inputs,
  withSystem,
  ...
}:

{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem =
    { system, ... }:

    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
        config.permittedInsecurePackages = [
          "broadcom-sta-6.30.223.271-59-6.12.59" # TODO: migrate to actually secure network drivers on bart-pc or get rid of wifi in its entirety
          "olm-3.2.16"
        ];

        overlays = [
          self.overlays.default
          self.overlays.plasmashell-workaround
          self.overlays.nix-auth

          inputs.copyparty.overlays.default
          inputs.headplane.overlays.default
          inputs.deploy-rs.overlays.default

          (_prev: _final: { invoice = inputs.invoice.packages.${system}.default; })
        ];
      };

      _module.args.stablePkgs = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      _module.args.personalPkgs = import inputs.nixpkgs-personal {
        inherit system;
        config.allowUnfree = true;
      };

      pkgsDirectory = ../pkgs;
    };

  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        local = config.packages;
      }
    );
}
