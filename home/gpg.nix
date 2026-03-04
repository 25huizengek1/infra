{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.optionals config.common.gui [ pkgs.kdePackages.kgpg ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
}
