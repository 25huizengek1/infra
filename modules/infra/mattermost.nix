{ config, ... }:

{
  services.mattermost = {
    enable = true;
    socket.enable = true;
    siteUrl = "https://chat.bartoostveen.nl";
  };

  services.nginx.virtualHosts."chat.bartoostveen.nl" = {
    enableACME = true;
    forceSSL = true;
    listenAddresses = [ "100.64.0.2" ];
    locations."/".proxyPass =
      "http://${config.services.mattermost.host}:${toString config.services.mattermost.port}";
  };
}
