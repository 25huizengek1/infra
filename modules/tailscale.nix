{ config, pkgs, ... }:

let
  domain = (import ../const.nix).domain;
  vhost = "headscale";
  fqdn = "${vhost}.${domain}";
in
{
  services.headscale = {
    enable = true;
    port = 41916;
    settings.server_url = "https://${fqdn}:443";
    settings.dns.base_domain = fqdn;
  };

  services.nginx.virtualHosts."${fqdn}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.headscale.address}:${toString config.services.headscale.port}";
      proxyWebsockets = true;
    };
    locations."/admin/" = {
      alias = "${pkgs.headscale-admin}/";
      index = "index.html";
    };
  };
  
  services.tailscale.enable = true;
}
