{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  kdePackages,
  openssl,
  libpulseaudio,
  qt6,
  installShellFiles,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "librepods";
  version = "0.1.0-rc.4";

  src = fetchFromGitHub {
    owner = "kavishdevar";
    repo = "librepods";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FnDYQ3EPx2hpeCCZvbf5PJo+KCj+YO+DNg+++UpZ7Xs=";
  };

  sourceRoot = "source/linux";

  nativeBuildInputs = [
    cmake

    kdePackages.qtbase
    kdePackages.qtconnectivity
    kdePackages.qtdeclarative
    kdePackages.qtmultimedia

    openssl
    libpulseaudio

    qt6.wrapQtAppsHook

    installShellFiles
    copyDesktopItems
  ];

  preInstall = ''
    mv applinux ${finalAttrs.meta.mainProgram}
    installBin ${finalAttrs.meta.mainProgram}
  '';

  # linux/assets/me.kavishdevar.librepods.desktop
  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "LibrePods";
      comment = finalAttrs.meta.description;
      icon = "librepods";
      exec = finalAttrs.meta.mainProgram;
      categories = [
        "Audio"
        "AudioVideo"
        "Utility"
        "Qt"
      ];
      terminal = false;
    })
  ];

  meta = {
    description = "AirPods liberated from Apple's ecosystem";
    homepage = "https://github.com/kavishdevar/librepods";
    changelog = "https://github.com/kavishdevar/librepods/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    mainProgram = "librepods";
    platforms = lib.platforms.all;
  };
})
