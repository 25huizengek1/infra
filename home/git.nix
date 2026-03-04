{ pkgs, ... }:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    signing = {
      key = "5963223E57296C53";
      signByDefault = true;
    };

    settings = {
      user.email = "bart@bartoostveen.nl";
      user.name = "Bart Oostveen";
      pull.rebase = true;
      init.defaultBranch = "master";
      advice.detachedHead = false;

      alias.fwlpush = "push --force-with-lease";
    };

    includes = [
      {
        condition = "hasconfig:remote.*.url:git@gitlab.utwente.nl:*/**";
        contents.user = {
          email = "b.oostveen@student.utwente.nl";
          name = "Oostveen, B. (Bart, Student B-TCS)";
          signingKey = "FAD453F45800E974";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@gitlab.snt.utwente.nl:*/**";
        contents.user = {
          email = "oostveen@snt.utwente.nl";
          name = "Bart Oostveen";
          signingKey = "2D4FB795E873C2C3";
        };
      }
    ];
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    extensions = with pkgs; [
      gh-dash
      local.gh-branch
      gh-notify
    ];
  };
}
