{
  pkgs,
  config,
  ...
}:

let
  port = toString 16013;
  domain = (import ../const.nix).domain;
  vhost = "attic.${domain}";
in
{
  services.atticd = {
    enable = true;
    package = pkgs.attic-server;

    environmentFile = config.sops.secrets.attic-env.path;

    settings = {
      listen = "127.0.0.1:${port}";

      jwt = { };

      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 16 * 1024;
        avg-size = 64 * 1024;
        max-size = 256 * 1024;
      };

      storage = {
        type = "s3";
        region = "us-east-1";
        bucket = "attic";
        endpoint = "minio.${domain}";
      };
    };
  };

  sops.secrets.attic-env = {
    format = "binary";
    sopsFile = ../secrets/attic.env.secret;
  };

  services.nginx.virtualHosts.${vhost} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${port}/";
      proxyWebsockets = true;
    };
  };
}
