{ inputs, config, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./bart-server.disk-config.nix

    inputs.nixos-facter-modules.nixosModules.facter

    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../containers/tcs-bot.nix
    ../containers/web.nix

    ../modules/wireguard.nix

    ../modules/infra/anubis.nix
    ../modules/infra/attic.nix
    ../modules/infra/authentik.nix
    ../modules/infra/autokuma.nix
    ../modules/infra/common.nix
    ../modules/infra/matrix
    ../modules/infra/copyparty.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/git.nix
    ../modules/infra/ical-proxy.nix
    ../modules/infra/ircbounce.nix
    ../modules/infra/mailserver
    ../modules/infra/maubot.nix
    ../modules/infra/monitoring.nix
    ../modules/infra/networking.nix
    ../modules/infra/nix.nix
    ../modules/infra/nginx.nix
    ../modules/infra/podman.nix
    ../modules/infra/search.nix
  ];

  facter.reportPath = ./bart-server.json;
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:c2c:2f66::1/128";

  srvos.prometheus.ruleGroups.srvosAlerts.alertRules.UnusualDiskReadLatency.enable = false;

  infra.copyparty = {
    enable = true;
    acme = true;
  };

  infra.wireguard.enable = true;

  infra.authentik = {
    enable = true;
    enablePrometheus = true;
    environmentFile = config.sops.secrets.authentik-env.path;
  };

  sops.secrets.authentik-env = {
    format = "binary";
    sopsFile = ../secrets/authentik.env.secret;

    owner = "authentik";
    group = "authentik";
    mode = "0660";
    restartUnits = [
      "authentik.service"
      "authentik-worker.service"
      "authentik-ldap.service"
    ];
  };

  system.stateVersion = "26.05";
}
