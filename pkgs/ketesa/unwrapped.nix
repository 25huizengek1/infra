{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ketesa";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "etkecc";
    repo = "ketesa";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Z9qtCvpyFkBhqKWn9+dre9alBJ0nwyEvE0m9X8xWbRo=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-nlyofNcvnANXHv26BZ7bNqpfnTQj7jw0lk0yhBGXsnc=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
  ];

  installPhase = ''
    runHook preInstall
    cp -r dist $out/
    runHook postInstall
  '';

  meta = {
    description = "Admin UI for Matrix servers, formerly Synapse Admin. Drop-in replacement with extended features, multi-backend support, and visual customization";
    homepage = "https://github.com/etkecc/ketesa";
    license = with lib.licenses; [
      bsd2
      asl20
      cc0
      mit
      ofl
    ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "ketesa";
    platforms = lib.platforms.all;
  };
})
