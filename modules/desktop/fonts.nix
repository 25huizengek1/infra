{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    enableGhostscriptFonts = true;
    fontconfig.useEmbeddedBitmaps = true;
    fontDir.enable = true;

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      scientifica
      (scientifica.overrideAttrs (_o: {
        nativeBuildInputs = [ nerd-font-patcher ];
        postInstall = ''
          mkdir -p $out/share/fonts/truetype/{scientifica,scientifica-nerd}
          mv $out/share/fonts/truetype/*.ttf $out/share/fonts/truetype/scientifica/
          for f in $out/share/fonts/truetype/scientifica/*.ttf; do
              nerd-font-patcher --complete --outputdir $out/share/fonts/truetype/scientifica-nerd/ $f
          done
        '';
      }))
    ];
  };
}
