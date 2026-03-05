{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-terminfo

    ../modules/infra/common.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/podman.nix
    ../modules/wireguard.nix
  ];

  boot.kernelParams = [
    "console=ttyS1,115200n8"
    "cma=320M"
  ];

  boot.initrd.kernelModules = [
    "vc4"
    "bcm2835_dma"
    "i2c_bcm2835"
  ];

  boot.loader.grub.enable = lib.mkForce false;

  nix.channel.enable = lib.mkForce false;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  systemd.services.btattach = {
    before = [ "bluetooth.service" ];
    after = [ "dev-ttyAMA0.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  hardware.enableRedistributableFirmware = true;
  networking.wireless.enable = true;

  networking.useNetworkd = true;
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true; # normally we wouldn't do this on servers, but oh well

  # infra.copyparty.enable = true;
  infra.wireguard.enable = true;

  system.stateVersion = "26.05";
}
