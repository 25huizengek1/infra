{ self, inputs, ... }:
{
  flake.pkgs = import inputs.nixpkgs rec {
    system = "x86_64-linux";
    config.android_sdk.accept_license = true;
    config.allowUnfree = true;
    overlays = [
      (_final: _prev: self.packages.${system})
      (final: _prev: {
        jdk8 = final.temurin-bin-8;
      })
      inputs.headplane.overlays.default
      inputs.copyparty.overlays.default
    ];
  };
}
