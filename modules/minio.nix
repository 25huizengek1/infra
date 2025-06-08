{ config, const, ... }:

let
  listenAddress = "127.0.0.1:22677";
  consoleAddress = "127.0.0.1:22678";
in
{
  services.minio = {
    enable = true;
    inherit listenAddress;
    inherit consoleAddress;
    rootCredentialsFile = config.sops.secrets.minio-credentials.path;
  };

  sops.secrets.minio-credentials = {
    format = "binary";
    sopsFile = ../secrets/minio-credentials.secret;

    owner = "minio";
    group = "minio";
    mode = "0600";
    restartUnits = [ "minio.service" ];
  };

  services.nginx.virtualHosts."minio-api.${const.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${listenAddress}";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."minio.${const.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${consoleAddress}";
      proxyWebsockets = true;
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "minio-job";
      metrics_path = "/minio/v2/metrics/cluster";
      scheme = "https";
      static_configs = [ { targets = [ "minio-api.${const.domain}" ]; } ];
    }
  ];
}
