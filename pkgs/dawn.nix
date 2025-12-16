{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  curl,
}:

stdenv.mkDerivation rec {
  pname = "dawn";
  version = "0.0.7";

  src = fetchFromGitHub {
    owner = "andrewmd5";
    repo = "dawn";
    tag = "v${version}";
    hash = "sha256-NtslTInBT3OZZ92auG2y/RIMwTY5lG5T7PzE02JFAoI=";
    fetchSubmodules = true;
  };

  patches = [
    ./dawn/0001-fix-correct-cmake-libdir.patch
  ];

  nativeBuildInputs = [
    cmake
    curl.dev
  ];

  meta = {
    description = "A distraction-free writing environment; draft anything, write now";
    homepage = "https://github.com/andrewmd5/dawn";
    license = lib.licenses.mit;
    mainProgram = "dawn";
    platforms = lib.platforms.all;
  };
}
