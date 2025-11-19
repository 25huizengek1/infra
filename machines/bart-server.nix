{
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops
    inputs.nixos-mailserver.nixosModule
    inputs.copyparty.nixosModules.default

    ./disk-config.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    inputs.srvos.nixosModules.mixins-terminfo
    inputs.srvos.nixosModules.mixins-telegraf
    inputs.srvos.nixosModules.mixins-terminfo
    inputs.srvos.nixosModules.mixins-nginx
    inputs.srvos.nixosModules.roles-prometheus

    ../containers/portainer.nix

    ../modules/anubis.nix
    ../modules/copyparty.nix
    ../modules/git.nix
    ../modules/ical-proxy.nix
    ../modules/mailserver
    ../modules/monitoring.nix
    ../modules/nix.nix
    ../modules/nginx.nix
    ../modules/search.nix
    ../modules/tailscale.nix
    ../modules/tcs-bot.nix
    ../modules/web.nix
  ];

  facter.reportPath = ./bart-server.json;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdc+Tbt0d+pHMYrDjrT3Ui09NV38T3bFWk/OMEL4Dp6 u0_a374@bart-phone"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJ38XOn6VETxKPzT5SS1s3GexJmUV4P9aTNSe71DpFW bart@bart-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4zwjOqILG37umIJNYYSMjveYzmwjOw/pTdfLbcsaSP bart@bart-laptop-new"
  ];

  environment.systemPackages = with pkgs; [
    curl
    gcc
    gh
    git
    gnutar
    unzip
    vscode-fhs
    wget
    zip

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

  services.redis.package = pkgs.valkey;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  services.postgresql = {
    authentication = lib.mkOverride 10 ''
      # type	database	user	origin-address	auth-method
      local	all		all			trust
      host	all		all	127.0.0.1/32	trust
      host	all		all	::1/128		trust
    '';
    identMap = ''
      # arbitraryMapName	systemUser	DBUser
      superuser_map		root		postgres
      superuser_map		postgres  	postgres

      # Let other names login as themselves
      superuser_map		/^(.*)$		\1
    '';
  };

  srvos.prometheus.ruleGroups.srvosAlerts.alertRules.UnusualDiskReadLatency.enable = false;

  system.stateVersion = "25.05";
}
