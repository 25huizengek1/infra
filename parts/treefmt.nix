{ inputs, ... }:

{
  imports = [ inputs.treefmt.flakeModule ];

  perSystem.treefmt = {
    programs.nixfmt.enable = true;
    programs.deadnix.enable = true;
  };
}
