{ self, inputs, ... }:
{
  flake.pkgs = import inputs.nixpkgs rec {
    system = "x86_64-linux";
    config.android_sdk.accept_license = true;
    config.allowUnfree = true;
    overlays = [
      (final: super: self.packages.${system})
      (final: super: { nginxStable = super.nginxStable.override { openssl = super.pkgs.libressl; }; })
      inputs.headplane.overlays.default
    ];
  };
}
