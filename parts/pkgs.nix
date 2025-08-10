{ self, inputs, ... }:
{
  flake.pkgs = import inputs.nixpkgs rec {
    system = "x86_64-linux";
    config.android_sdk.accept_license = true;
    config.allowUnfree = true;
    overlays = [
      (_final: _prev: self.packages.${system})
      (
        final: prev:
        let
          headplanePkgs = inputs.headplane.overlays.default final prev;
        in
        headplanePkgs
        // {
          headplane = (
            headplanePkgs.headplane.overrideAttrs (
              finalPkg: prevPkg: {
                pnpmDeps = final.pnpm_10.fetchDeps {
                  inherit (finalPkg) pname version src;
                  fetcherVersion = 2;
                  hash = "sha256-CsrZjXl31sl/YRzpt/pyBtr4QKn1pLRHqu5hUcNVZbo=";
                };
              }
            )
          );
        }
      )
      (final: _prev: {
        jdk8 = final.temurin-bin-8;
      })
      inputs.copyparty.overlays.default
    ];
  };
}
