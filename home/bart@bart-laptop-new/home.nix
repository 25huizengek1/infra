{
  imports = [
    ../alacritty.nix
    ../common.nix
    ../copyparty-fuse.nix
    ../git.nix
    ../gpg.nix
    ../jetbrains.nix
    ../plasma.nix
    ../tmux.nix
  ];

  common.gui = true;
}
