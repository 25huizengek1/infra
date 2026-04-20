{
  modulesPath,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
    ../modules/desktop/networking.nix
  ];

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];
  nix.channel.enable = lib.mkForce false;
  networking.hostName = "nixos-installer";

  programs.nh.enable = true;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  environment = {
    systemPackages = with pkgs; [
      alacritty
      gh
      git
    ];
    variables.NH_SHOW_ACTIVATION_LOGS = 1;
  };
}
