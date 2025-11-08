{ self, inputs, ... }:
{
  flake.pkgs = import inputs.nixpkgs rec {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = [
      (_final: _prev: self.packages.${system})
      inputs.headplane.overlays.default
      inputs.copyparty.overlays.default
    ];
  };
}
