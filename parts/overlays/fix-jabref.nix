{
  flake.overlays.fix-jabref = (
    final: prev: {
      jabref = prev.jabref.overrideAttrs (old: {
        postFixup = old.postFixup + ''
          for bin in jabgui jabkit jabsrv-cli; do
            substituteInPlace $out/bin/$bin \
              --replace "-Djava.library.path=$out/lib/" \
                        "-Dglass.gtk.uiScale=1.5 -Djava.library.path=$out/lib/"
          done
        '';
      });
    }
  );
}
