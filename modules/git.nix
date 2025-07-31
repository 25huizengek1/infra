{ ... }:

{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.git = {
    enable = true;
    config = {
      user.signingKey = "31805D4650DE1EC8";
      user.name = "25huizengek1";
      user.email = "25huizengek1@gmail.com";
      commit.gpgSign = true;
      tag.gpgSign = true;
      pull.rebase = true;
      init.defaultBranch = "master";
      advice.detachedHead = false;
    };
  };

  programs.bash.interactiveShellInit = ''
    GPG_TTY=$(tty)
  '';
}