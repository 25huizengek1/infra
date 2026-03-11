{
  self,
  inputs,
  ...
}:

{
  perSystem =
    { system, pkgs, ... }:

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

      # keep-sorted start
      packages.alertmanager-matrix = pkgs.callPackage ../pkgs/alertmanager-matrix/package.nix { };
      packages.autokuma = pkgs.callPackage ../pkgs/autokuma/package.nix { };
      packages.dawn = pkgs.callPackage ../pkgs/dawn/package.nix { };
      packages.fail2ban-prometheus-exporter =
        pkgs.callPackage ../pkgs/fail2ban-prometheus-exporter/package.nix
          { };
      packages.gh-branch = pkgs.callPackage ../pkgs/gh-branch/package.nix { };
      packages.github-readme-stats = pkgs.callPackage ../pkgs/github-readme-stats/package.nix { };
      packages.librepods = pkgs.callPackage ../pkgs/librepods/package.nix { };
      packages.matrix-stickerbook = pkgs.callPackage ../pkgs/matrix-stickerbook/package.nix { };
      packages.meshcore-gui = pkgs.callPackage ../pkgs/meshcore-gui/package.nix { };
      packages.meshcore-scan = pkgs.callPackage ../pkgs/meshcore-scan/package.nix { };
      packages.meshcoredecoder = pkgs.callPackage ../pkgs/meshcoredecoder/package.nix { };
      packages.tilp = pkgs.callPackage ../pkgs/tilp/package.nix { };
      packages.wp-oidc-roles = pkgs.callPackage ../pkgs/wp-oidc-roles/package.nix { };
      # keep-sorted end
    };
}
