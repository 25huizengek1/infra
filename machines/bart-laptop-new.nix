{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./bart-laptop-new.hardware.nix

    ../modules/desktop/users/bart.nix

    ../modules/desktop/android.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/bluetooth.nix
    ../modules/desktop/copyparty-fuse.nix
    ../modules/desktop/common.nix
    ../modules/desktop/fonts.nix
    ../modules/desktop/i18n.nix
    ../modules/desktop/kde.nix
    ../modules/desktop/network-profiles.nix
    ../modules/desktop/networking.nix
    ../modules/desktop/podman.nix
    ../modules/desktop/printing.nix
    ../modules/desktop/sudo.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
    };
  };

  time.hardwareClockInLocalTime = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  services.displayManager.sddm.enable = lib.mkForce false;
  services.displayManager.gdm.enable = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  environment.systemPackages = with pkgs; [
    kdePackages.krfb
    kdePackages.krdc
  ];

  programs.steam.enable = true;

  system.stateVersion = "25.11";
}
