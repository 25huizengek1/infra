{ lib, ... }:

{
  programs.gnupg.agent = {
    enable = lib.mkDefault true;
    enableSSHSupport = true;
  };

  programs.git = {
    enable = lib.mkDefault true;
    config = {
      user.signingKey = "5963223E57296C53";
      user.name = "Bart Oostveen";
      user.email = "bart@bartoostveen.nl";
      commit.gpgSign = true;
      tag.gpgSign = true;
      pull.rebase = true;
      init.defaultBranch = "master";
      advice.detachedHead = false;
    };
  };

  programs.bash.interactiveShellInit = lib.mkDefault ''
    GPG_TTY=$(tty)
  '';
}
