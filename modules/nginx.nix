{ ... }: {
  services.nginx = {
    enable = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;

    virtualHosts."portainer.omeduostuurcentenneef.nl" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://127.0.0.1:9943";
        extraConfig = "proxy_ssl_server_name on;proxy_pass_header Authorization;";
      };
    };

    virtualHosts."cockpit.omeduostuurcentenneef.nl" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://127.0.0.1:9090";
        extraConfig = "proxy_ssl_server_name on;proxy_pass_header Authorization;";
      };
    };
  };
}