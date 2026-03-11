{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "autokuma";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "BigBoot";
    repo = "AutoKuma";
    rev = "0f65a5d5c3a46db1b4bfecc5fc635c49aa2e15a9";
    hash = "sha256-IxizYf6fwZ1VhEXZLGHlWkN3+p45mDXSd2nIu40sEM4=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  patches = [
    ./no-doctest.patch
    ./fix-dynamic-dispatch.patch
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  postInstall = ''
    mv $out/bin/crdgen $out/bin/autokuma-crdgen
  '';

  meta = {
    description = "Utility that automates the creation of Uptime Kuma monitors";
    homepage = "https://github.com/BigBoot/AutoKuma";
    mainProgram = "autokuma";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ hougo ];
  };
})
