{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "headscale-admin";
  version = "0.25.6";

  src = fetchFromGitHub {
    owner = "GoodiesHQ";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-qAihn3RUSUbl/NfN0sISKHJvyD7zj0E+VDVtlEpw8y4=";
  };

  npmDepsHash = "sha256-yu52aOSKXlRxM8jmADiiBkr/NI5c1zFFOdBHoJHWd2c=";
  npmPackFlags = [ "--ignore-scripts" ];

  installPhase = ''
    mv build $out
  '';

  meta = {
    description = "Admin Web Interface for juanfont/headscale";
    homepage = "https://github.com/GoodiesHQ/headscale-admin";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ 
      # TODO
    ];
    mainProgram = "headscale-admin";
    platforms = lib.platforms.all;
  };
}
