{ self, inputs, ... }:

{
  perSystem =
    { system, ... }:

    {
      _module.args.pkgs = import inputs.nixpkgs rec {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (_final: _prev: self.packages.${system})
          inputs.headplane.overlays.default
          inputs.copyparty.overlays.default
          inputs.deploy-rs.overlays.default
        ];
      };
    };
}
