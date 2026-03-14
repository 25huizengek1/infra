{
  lib,
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "roundcube-oidc";
  version = "1.2.9";

  src = fetchzip {
    url = "https://github.com/pulsejet/roundcube-oidc/releases/download/${finalAttrs.version}/roundcube_oidc.zip";
    hash = "sha256-yGCg4AVr9ADC/c+porZvrON1V0SYyP34MYpi9bWH0bg=";
  };

  installPhase = ''
    mkdir -p $out/plugins/roundcube_oidc
    cp -R * $out/plugins/roundcube_oidc/
  '';

  meta = {
    description = "OpenID Connect authentication plugin for Roundcube";
    homepage = "https://github.com/pulsejet/roundcube-oidc";
    license = lib.licenses.mit;
    mainProgram = "roundcube-oidc";
    platforms = lib.platforms.all;
  };
})
