{ lib, inputs, ... }:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
    ./atlas.firmware.nix

    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-terminfo

    ../modules/infra/common.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/podman.nix
    ../modules/wireguard.nix
  ];

  srvos.boot.consoles = [ ];

  nix.channel.enable = lib.mkForce false;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # normally we wouldn't do this on servers, but oh well
  networking.networkmanager.enable = true;
  networking.useNetworkd = true;

  # infra.copyparty.enable = true;
  infra.wireguard.enable = true;

  system.stateVersion = "26.05";
}
