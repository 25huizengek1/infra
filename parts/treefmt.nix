{
  perSystem.treefmt = {
    programs.nixfmt.enable = true;
    programs.deadnix = {
      enable = true;
      no-lambda-arg = true;
      no-lambda-pattern-names = true;
      no-underscore = true;
    };
  };
}
