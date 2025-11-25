{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fzf,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "gh-branch";
  version = "unstable-2023-12-06";

  src = fetchFromGitHub {
    owner = "mislav";
    repo = "gh-branch";
    rev = "7ed0aff7601dc4162e0cac8835ecd73409d8a009";
    hash = "sha256-yiRSXU/jLi067i+gBb3cEHTOuo+w3oEVsGL0NN6shl8=";
  };

  buildPhase = ''
    mkdir -p $out/bin
    mv gh-branch $out/bin
    wrapProgram $out/bin/gh-branch \
      --prefix PATH : ${lib.makeBinPath [ fzf ]}
  '';

  nativeBuildInputs = [ makeWrapper ];

  meta = {
    description = "GitHub CLI extension for fuzzy finding, quickly switching between and deleting branches";
    homepage = "https://github.com/mislav/gh-branch";
    license = lib.licenses.unlicense;
    mainProgram = "gh-branch";
    platforms = lib.platforms.all;
  };
}
