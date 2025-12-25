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

    ../modules/infra/anubis.nix
    ../modules/infra/common.nix
    ../modules/infra/copyparty.nix
    ../modules/infra/git.nix
    ../modules/infra/ical-proxy.nix
    ../modules/infra/immich.nix
    ../modules/infra/mailserver
    ../modules/infra/monitoring.nix
    ../modules/infra/nix.nix
    ../modules/infra/nginx.nix
    ../modules/infra/podman.nix
    ../modules/infra/search.nix
    ../modules/infra/tailscale.nix
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

  services.nginx.virtualHosts."laptop.omeduostuurcentenneef.nl" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://100.64.0.8:6969/";
      proxyWebsockets = true;
    };
  };

  system.stateVersion = "25.11";
}
