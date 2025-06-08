{ config, ... }:

{
  services.rathole = {
    enable = true;
    role = "server";
    settings.server = {
      bind_addr = "0.0.0.0:2333";
      services.vintagestory.bind_addr = "0.0.0.0:42420";
    };
    credentialsFile = config.sops.secrets.rathole-server.path;
  };

  networking.firewall.allowedTCPPorts = [
    2333
    42420
  ];

  sops.secrets.rathole-server = {
    mode = "0444";
    sopsFile = ../secrets/rathole-server.shared.secret;
    format = "binary";
  };
}