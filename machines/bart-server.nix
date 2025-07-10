{
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:

{
  imports = [
    ./disk-config.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    # ../containers/portainer.nix
    # ../containers/jenkins.nix
    ../modules/android.nix
    ../modules/anubis.nix
    ../modules/mailserver
    ../modules/monitoring.nix
    ../modules/nginx.nix
    ../modules/remotebuild.nix
    ../modules/tailscale.nix
    ../modules/tom.nix
    ../modules/weblate.nix
    ../modules/vscode.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.channel.enable = false;
  nix.gc.automatic = lib.mkForce false;

  nixpkgs.hostPlatform.system = "x86_64-linux";

  boot.loader.grub = {
    enable = true;

    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:c2c:2f66::1";

  networking = {
    hostName = hostname;
    domain = (import ../const.nix).domain;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        22
      ];
    };
  };

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKO4+0nbySi9L5GSXTExGCWdkZBqi5WEqYB9fr4LwKyh bart@bart-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdc+Tbt0d+pHMYrDjrT3Ui09NV38T3bFWk/OMEL4Dp6 u0_a374@bart-phone"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJ38XOn6VETxKPzT5SS1s3GexJmUV4P9aTNSe71DpFW bart@bart-pc"
  ];

  environment.systemPackages = with pkgs; [
    curl
    gcc
    gh
    git
    gnutar
    nodejs_24
    unzip
    vscode-fhs
    wget
    zip

    # Podman
    dive
    podman-compose
    podman-tui
  ];

  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  services.redis.package = pkgs.valkey; # Based

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  system.stateVersion = "25.05";
}
