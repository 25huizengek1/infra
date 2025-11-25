{
  pkgs,
  ...
}:

{
  imports = [
    ./bart-laptop.hardware.nix

    ../modules/desktop/users/bart.nix

    ../modules/desktop/audio.nix
    ../modules/desktop/bluetooth.nix
    ../modules/desktop/common.nix
    ../modules/desktop/i18n.nix
    ../modules/desktop/kde.nix
    ../modules/desktop/networking.nix
    ../modules/desktop/sudo.nix
  ];

  boot.loader.grub.device = "/dev/sda";

  environment.systemPackages = with pkgs; [
    kdePackages.krfb
    kdePackages.krdc
  ];

  system.stateVersion = "25.11";
}
