{ pkgs, ... }:

{
  home.packages = [ pkgs.kdePackages.kgpg ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
}
