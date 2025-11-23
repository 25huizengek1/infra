{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter

    ./server.disk-config.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../containers/portainer.nix
    ../containers/tcs-bot.nix
    ../containers/web.nix

    ../modules/anubis.nix
    ../modules/common.nix
    ../modules/copyparty.nix
    ../modules/git.nix
    ../modules/ical-proxy.nix
    ../modules/immich.nix
    ../modules/mailserver
    ../modules/monitoring.nix
    ../modules/nix.nix
    ../modules/nginx.nix
    ../modules/podman.nix
    ../modules/search.nix
    ../modules/tailscale.nix
  ];

  facter.reportPath = ./bart-server.json;
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:c2c:2f66::1";

  networking.firewall.allowedTCPPorts = [
    80
    443
    22
  ];

  srvos.prometheus.ruleGroups.srvosAlerts.alertRules.UnusualDiskReadLatency.enable = false;

  infra.copyparty = {
    enable = true;
    acme = true;
  };

  system.stateVersion = "25.05";
}
