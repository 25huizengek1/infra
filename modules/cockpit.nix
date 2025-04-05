{ ... }:

let
  port = 9090;
  domain = (import ../const.nix).domain;
in
{
  services.cockpit = {
    enable = true;
    port = port;
    openFirewall = false;
  };

  services.nginx.virtualHosts."cockpit.${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "https://127.0.0.1:${toString port}/";
      proxyWebsockets = true;
    };
  };
}
