{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./vector.disk-config.nix

    inputs.nixos-facter-modules.nixosModules.facter

    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../modules/wireguard.nix

    # ../modules/infra/anubis.nix # TODO: authentik behind anubis
    ../modules/infra/common.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/nix.nix
    ../modules/infra/nginx.nix
    ../modules/infra/podman.nix

    ../modules/infra/system-specific/vector/auth.nix
    ../modules/infra/system-specific/vector/mail.nix
    ../modules/infra/system-specific/vector/monitoring.nix
    ../modules/infra/system-specific/vector/wordpress.nix
  ];

  facter.reportPath = ./vector.json;
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:1c19:1cd2::1/64";

  infra.wireguard.enable = true;

  system.stateVersion = "26.05";
}
