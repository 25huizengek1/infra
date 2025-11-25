{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkDefault
    types
    ;

  cfg = config.git;
in
{
  options = {
    git.enable = mkEnableOption "git";

    git.user.email = mkOption {
      description = "git config --global user.email";
      type = types.str;
      default = "example@example.com";
    };

    git.user.name = mkOption {
      description = "git config --global user.name";
      type = types.str;
      default = "Unknown";
    };

    git.key = mkOption {
      description = "The signing key used for Git commits";
      type = types.nullOr types.str;
      default = null;
    };

    git.gh = mkOption {
      description = "gh cli integration";
      type = types.submodule {
        options = {
          enable = mkEnableOption "the gh cli";
          extensions = mkOption {
            description = "Extensions for gh";
            type = types.listOf types.package;
            default = with pkgs; [
              gh-dash
              local.gh-branch
              gh-notify
            ];
          };
        };
      };
      default = { };
    };
  };

  config = mkIf cfg.enable {
    programs.delta.enableGitIntegration = mkDefault true;

    programs.git = {
      enable = true;

      package = pkgs.gitFull;

      signing = mkIf (cfg.key != null) {
        key = cfg.key;
        signByDefault = true;
      };

      settings = {
        user.email = cfg.user.email;
        user.name = cfg.user.name;
        pull.rebase = true;
        init.defaultBranch = "master";
        advice.detachedHead = false;
      };
    };

    programs.gh = mkIf cfg.gh.enable {
      enable = true;
      gitCredentialHelper.enable = true;
      inherit (cfg.gh) extensions;
    };
  };
}
