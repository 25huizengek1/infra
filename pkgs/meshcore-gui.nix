{
  lib,
  fetchFromGitHub,
  python313Packages,
  bluez,
  local,
}:

python313Packages.buildPythonApplication (_finalAttrs: {
  pname = "meshcore-gui";
  version = "unstable-2026-02-05";

  src = fetchFromGitHub {
    owner = "pe1hvh";
    repo = "meshcore-gui";
    rev = "70cba6ecb81f7ea361a63845f56b0dcdc388a9c6";
    hash = "sha256-YGyGc2xwJ0RU7yEqajOwQkVBtYlaK2yj7mbJC+vQdj0=";
  };

  format = "other";

  dependencies = with python313Packages; [
    nicegui
    meshcore
    bleak
    local.meshcoredecoder
  ];

  buildInputs = [
    bluez
  ];

  installPhase = ''
    mkdir -p $out/bin
    install -m755 $src/meshcore_gui.py $out/bin/meshcore-gui
  '';

  meta = {
    description = "Native desktop GUI for MeshCore mesh network devices via BLE — no firmware changes required";
    homepage = "https://github.com/pe1hvh/meshcore-gui";
    license = lib.licenses.mit;
    mainProgram = "meshcore-gui";
    platforms = lib.platforms.all;
    broken = true; # TODO: actually properly package this using pyproject/setuptools, probably best to submit something upstream
  };
})
