{
  pkgs,
  ...
}:

{
  imports = [
    ./bart-pc.hardware.nix

    ../modules/desktop/users/bart.nix

    ../modules/desktop/android.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/bluetooth.nix
    ../modules/desktop/common.nix
    ../modules/desktop/copyparty-fuse.nix
    ../modules/desktop/fonts.nix
    ../modules/desktop/i18n.nix
    ../modules/desktop/kde.nix
    ../modules/desktop/kvm.nix
    ../modules/desktop/network-profiles.nix
    ../modules/desktop/networking.nix
    ../modules/desktop/nvidia.nix
    ../modules/desktop/obs-studio.nix
    ../modules/desktop/podman.nix
    ../modules/desktop/printing.nix
    ../modules/desktop/sudo.nix
  ];

  boot.loader.grub =
    let
      gfxmode = "1920x1080-75";
    in
    {
      device = "/dev/nvme0n1";
      gfxmodeEfi = gfxmode;
      gfxmodeBios = gfxmode;
    };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  hardware.firmware = [ pkgs.rtl8761b-firmware ];

  services.davfs2.enable = true;
  environment.systemPackages = with pkgs; [
    kdePackages.krfb
    kdePackages.krdc

    wineWowPackages.stableFull
    winetricks
    wineWowPackages.waylandFull

    (writeShellScriptBin "wine64" ''${lib.getExe wineWowPackages.stableFull} "$@"'')
  ];

  networking.firewall.allowedTCPPorts = [ 5900 ];
  networking.firewall.allowedUDPPorts = [ 5900 ];

  programs.steam.enable = true;

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  system.stateVersion = "25.11";
}
