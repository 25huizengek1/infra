{
  self,
  inputs,
  ...
}:

{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem =
    { system, ... }:

    let
      mkSimplePkgs =
        p:
        import p {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
        config.permittedInsecurePackages = [
          "olm-3.2.16"
        ];

        overlays = [
          self.overlays.default
          self.overlays.nix-auth
          self.overlays.invoice
          self.overlays.fix-jabref

          inputs.copyparty.overlays.default
          inputs.deploy-rs.overlays.default
        ];
      };

      _module.args.stablePkgs = mkSimplePkgs inputs.nixpkgs-stable;
      _module.args.personalPkgs = mkSimplePkgs inputs.nixpkgs-personal;

      pkgsDirectory = ../pkgs;
    };
}
