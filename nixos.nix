{
  pkgs,
  inputs,
  hostname,
  ...
}:
{
  imports = [
    ./disk-config.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.channel.enable = false;

  boot.loader.grub = {
    enable = true;

    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:c2c:2f66::1";

  networking = {
    hostName = hostname;
    domain = "omeduostuurcentenneef.nl";

    firewall.allowedTCPPorts = [
      80
      443
      22
    ];
  };

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKO4+0nbySi9L5GSXTExGCWdkZBqi5WEqYB9fr4LwKyh bart@bart-laptop"
  ];

  environment.systemPackages = with pkgs; [
    curl
    gcc
    gh
    git
    gnutar
    nodejs_23
    unzip
    wget
    zip
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  system.stateVersion = "25.05";
}
