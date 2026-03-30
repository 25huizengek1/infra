{
  lib,
  fetchFromGitHub,
  php,
  writeText,
  runCommand,
  configText ? "",
}:

let
  config = writeText "roundcube-oidc-config.php" configText;
  configChecked = runCommand "roundcube-oidc-config-checked" { } ''
    ${lib.getExe php} -l ${config}
    cp ${config} $out
  '';
in
php.buildComposerProject2 (_finalAttrs: {
  pname = "roundcube-oidc";
  version = "1.2.9";

  src = fetchFromGitHub {
    owner = "bartoostveen";
    repo = "roundcube-oidc";
    rev = "e8e4e4cd5421c1f01e1e05f9804b04cbf781e1fa";
    hash = "sha256-VYVWHoYFaNfAg0alIjNS187KoWdAr93744VtKlwqBDU=";
  };

  vendorHash = "sha256-n6xV5LIAyquQr1HsPJa5j/Mb9OVUW+101+hvpFbffO8=";
  composerStrictValidation = false;

  installPhase = ''
    mkdir -p $out/plugins/roundcube_oidc
    cp -R * $out/plugins/roundcube_oidc/
    cp ${configChecked} $out/plugins/roundcube_oidc/config.inc.php
  '';

  meta = {
    description = "OpenID Connect authentication plugin for Roundcube";
    homepage = "https://github.com/pulsejet/roundcube-oidc";
    license = lib.licenses.mit;
    mainProgram = "roundcube-oidc";
    platforms = lib.platforms.all;
  };
})
