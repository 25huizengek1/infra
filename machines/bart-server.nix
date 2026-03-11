{ inputs, config, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./bart-server.disk-config.nix

    inputs.nixos-facter-modules.nixosModules.facter

    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../modules/wireguard.nix

    ../modules/infra/system-specific/main/containers/tcs-bot.nix
    ../modules/infra/system-specific/main/containers/web.nix
    ../modules/infra/system-specific/main/attic.nix
    ../modules/infra/system-specific/main/ical-proxy.nix
    ../modules/infra/system-specific/main/ircbounce.nix
    ../modules/infra/system-specific/main/mailserver
    ../modules/infra/system-specific/main/maubot.nix
    ../modules/infra/system-specific/main/monitoring.nix
    ../modules/infra/system-specific/main/search.nix
    ../modules/infra/system-specific/main/wireguard.monitoring.nix

    ../modules/infra/anubis.nix
    ../modules/infra/authentik.nix
    ../modules/infra/autokuma.nix
    ../modules/infra/common.nix
    ../modules/infra/matrix
    ../modules/infra/copyparty.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/nix.nix
    ../modules/infra/nginx.nix
    ../modules/infra/podman.nix
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
