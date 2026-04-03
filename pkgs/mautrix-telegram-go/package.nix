{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  olm,
  withGoOlm ? false,
}:

buildGoModule (finalAttrs: {
  pname = "mautrix-telegram";
  version = "0-unstable-2026-04-02";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "telegram";
    rev = "e7099d26f39922c32a6d57890860abb573b1cb0c";
    hash = "sha256-CZdMNcvcZtx01cTVnymECMVINDdD2kqwCpcXeHf3pcU=";
  };

  vendorHash = "sha256-/fa/FDajT+wnJFP/QNw0NpA4IRWr1f09rDYqwaRG+es=";

  ldflags = [
    "-X"
    # "main.Tag=${finalAttrs.version}"
    "main.Tag=v0.2604.2"
  ];

  buildInputs = (lib.optional (!withGoOlm) olm) ++ [ stdenv.cc.cc.lib ];

  doCheck = false;
  doInstallCheck = false;

  tags = lib.optional withGoOlm "goolm";

  meta = {
    description = "A Matrix-Telegram puppeting bridge";
    homepage = "https://github.com/mautrix/telegram";
    changelog = "https://github.com/mautrix/telegram/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "mautrix-telegram";
  };
})
