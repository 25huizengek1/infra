{
  modulesPath,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

  nix.channel.enable = lib.mkForce false;
  networking.hostName = "nixos-installer";

  environment.systemPackages = with pkgs; [
    gh
    git
  ];
}
