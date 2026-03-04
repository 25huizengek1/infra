{ pkgs, ... }:

{
  mkElementCall =
    elementCallConfig:
    pkgs.element-call.overrideAttrs {
      postInstall = ''
        install ${pkgs.writers.writeJSON "element-call.json" elementCallConfig} $out/config.json
      '';
    };
}
