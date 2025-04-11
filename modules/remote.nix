{ config, ... }:

{
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    signal.relayHosts = [ "127.0.0.1" ];
  };
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}
