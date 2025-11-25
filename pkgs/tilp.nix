{
  lib,
  stdenv,
  fetchFromGitHub,
  pkgs,
}:

stdenv.mkDerivation rec {
  pname = "tilp";
  version = "1.18";

  nativeBuildInputs = with pkgs; [
    autoconf
    automake
    bison
    flex
    gettext
    glib.dev
    gnome2.libglade.dev
    groff
    gtk2.dev
    intltool
    libarchive.dev
    libticables2
    libticalcs2
    libticonv
    libtifiles2
    libtool
    libusb1.dev
    pkg-config
    texinfo
    xdg-utils
    xz
    zlib.dev
  ];

  src =
    fetchFromGitHub {
      owner = "debrouxl";
      repo = "tilp_and_gfm";
      rev = version;
      hash = "sha256-/XkxEfWzJiOkM5aoenp/GQSkkNg9qoXkFtcj/nenFEw=";
    }
    + "/tilp/trunk";

  configurePhase = ''
    autoreconf -i -v -f
    mkdir -p $out
    ./configure --prefix=$out
  '';

  meta = {
    description = "TILP (formerly GtkTiLink) can transfer data between Texas Instruments graphing calculators and a computer. It works with all link cables (parallel, serial, Black/Gray/Silver/Direct Link) and it supports the TI-Z80 series (73..86), the TI-eZ80 series (83PCE, 84+CE), the TI-68k series (89, 92, 92+, V200, 89T) and the Nspire series (Nspire Clickpad / Touchpad / CX, both CAS and non-CAS";
    homepage = "https://github.com/debrouxl/tilp_and_gfm/tree/1.18/tilp/trunk";
    license = lib.licenses.gpl2Only;
    mainProgram = "tilp";
    platforms = lib.platforms.all;
  };
}
