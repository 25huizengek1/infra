{
  callPackage,
  stdenv,
  ketesa ? callPackage ./unwrapped.nix { },
  conf ? { },
}:

if (conf == { }) then
  ketesa
else
  stdenv.mkDerivation {
    pname = "${ketesa.pname}-wrapped";
    inherit (ketesa) version meta;

    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      ln -s ${ketesa}/* $out
      rm $out/config.json
      cp ${builtins.toFile "ketesa-config.json" (builtins.toJSON conf)} $out/config.json
    '';
  }
