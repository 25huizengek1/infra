{ config, ... }:

let
  domain = "maubot.bartoostveen.nl";
in
{
  services.maubot = {
    enable = true;
    configMutable = false;
    plugins = with config.services.maubot.package.plugins; [
      echo
    ];
    settings = {
      server.hostname = "127.0.0.1";
      server.public_url = "https://${domain}";
      homeservers.default.url = "https://matrix.bartoostveen.nl";
      admins.bart = "$2b$15$uDScMFzqQJSOfMpveaN.W.vS7x9yNPd4boS4nFZrxqBN6bqZ7cMim";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass =
      "http://${config.services.maubot.settings.server.hostname}:${toString config.services.maubot.settings.server.port}";
  };
}
