{ inputs, ... }:

{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem.treefmt = {
    programs.nixfmt.enable = true;
    programs.deadnix.enable = true;
    programs.statix.enable = true;
    programs.flake-edit.enable = true;
    programs.keep-sorted.enable = true;
    programs.shellcheck.enable = true;
  };
}
