{ config, ... }:

{
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}
