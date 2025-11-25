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
          "broadcom-sta-6.30.223.271-59-6.12.58" # TODO: migrate to actually secure network drivers on bart-pc or get rid of wifi in its entirety
        ];

        overlays = [
          self.overlays.default
          self.overlays.plasmashell-workaround

          inputs.copyparty.overlays.default
          inputs.headplane.overlays.default
          inputs.deploy-rs.overlays.default

          (_prev: _final: { invoice = inputs.invoice.packages.${system}.default; })
        ];
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
