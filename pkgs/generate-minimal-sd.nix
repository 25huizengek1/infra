{
  nixos-generators,
  writeShellScriptBin,
  lib,
  ...
}:

writeShellScriptBin "generate-minimal-sd" ''
  ${lib.getExe nixos-generators} -f qcow --flake .#minimal-sd --system x86_64-linux -o hd.qcow2
''
