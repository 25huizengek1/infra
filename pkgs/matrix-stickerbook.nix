{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "matrix-stickerbook";
  version = "0-unstable-2026-02-16";

  src = fetchFromGitHub {
    owner = "liminalpurple";
    repo = "matrix-stickerbook";
    rev = "59c40f4a04f390d8f53c8c1da7c18bc7186660e3";
    hash = "sha256-IA8tHcOlAN1YgujqH0WNrS//axnKhm9OMQ2ukRmVuo8=";
  };

  patches = [ ./matrix-stickerbook/0001-fix-go-1.25.5.patch ];

  vendorHash = "sha256-oT9VwHQALPWe7eMUrOHOxHP/qzt3laW6FmFzf2phnyg=";

  ldflags = [ "-s" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Sticker management system for Matrix";
    homepage = "https://github.com/liminalpurple/matrix-stickerbook";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "stickerbook";
  };
})
