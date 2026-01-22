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
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    alacritty
    gh
    git
  ];
}
