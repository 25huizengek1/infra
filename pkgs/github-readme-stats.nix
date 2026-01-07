{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
  nodejs_25,
  applyPatches,
}:

buildNpmPackage (finalAttrs: {
  pname = "github-readme-stats";
  version = "0-unstable-2025-12-21";

  src = fetchFromGitHub {
    owner = "anuraghazra";
    repo = "github-readme-stats";
    rev = "8108ba1417faaad7182399e01dd724777adc63e5";
    hash = "sha256-DV9Gx6R9qn0ZST+U8VwHeYJJApuifriY2i8r9eunXn0=";
  };

  patches = [
    # as specified in https://github.com/anuraghazra/github-readme-stats?tab=readme-ov-file#on-other-platforms
    ./github-readme-stats-fix-express-dependency.patch
  ];

  npmDeps = importNpmLock {
    npmRoot = applyPatches {
      inherit (finalAttrs) src patches;
    };
    packageLock = builtins.fromJSON (builtins.readFile ./github-readme-stats-package-lock.json);
  };
  npmConfigHook = importNpmLock.npmConfigHook;

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out/
    makeWrapper ${lib.getExe nodejs_25} $out/bin/${finalAttrs.pname} --append-flag "$out/express.js"
    runHook postInstall
  '';

  meta = {
    description = "Zap: Dynamically generated stats for your github readmes";
    homepage = "https://github.com/anuraghazra/github-readme-stats";
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
    platforms = lib.platforms.all;
  };
})
