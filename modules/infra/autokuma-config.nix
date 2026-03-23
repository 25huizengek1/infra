{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# TODO: clean up the fact that (reachability) metadata of other hosts is basically all over the place

let
  inherit (lib) mkDefault genAttrs attrNames;
in
{
  imports = [
    ./autokuma.nix
  ];

  infra.autokuma = {
    enable = mkDefault true;
    package = pkgs.local.autokuma;
    defaultEnvFile = config.sops.secrets.autokuma-env.path;
    defaultSettings = {
      kuma = {
        url = "http://10.0.0.1:${toString inputs.self.nixosConfigurations.bart-server.config.services.uptime-kuma.settings.PORT}";
        username = "adm";
      };
      tag_name = "Managed by AutoKuma @ ${config.networking.hostName}";
      tag_color = "#ea2121";
    };
    instances.local = {
      additionalMonitorFiles = [ config.sops.secrets.autokuma-matrix.path ];
      tags = {
        nginx = {
          name = "nginx @ ${config.networking.hostName}";
          color = "#17964a";
        };
        autokuma = {
          name = "Managed by AutoKuma @ ${config.networking.hostName}";
          color = "#ea2121";
        };
      };
      monitors =
        genAttrs
          (builtins.filter (kumaVHost: kumaVHost != "localhost") (
            attrNames config.services.nginx.virtualHosts
          ))
          (kumaVHost: {
            type = "http";
            name = kumaVHost;
            description = "nginx Managed by AutoKuma @ ${config.networking.hostName}";
            expiry_notification = true;
            url = "https://${kumaVHost}";
            accepted_statuscodes = [ "200-399" ];
            notification_name_list = [ "autokuma-matrix" ];
            tag_names = [
              {
                name = "nginx";
                value = kumaVHost;
              }
              {
                name = "autokuma";
                value = "nginx";
              }
            ];
            timeout = 10;
            interval = 20;
            retry_interval = 20;
          });
    };
  };

  systemd.services.autokuma-local.serviceConfig.SupplementaryGroups = "podman";

  sops.secrets.autokuma-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../../secrets/autokuma.env.secret;
    format = "binary";
    restartUnits = [ "autokuma-local.service" ];
  };

  sops.secrets.autokuma-matrix = {
    owner = "autokuma";
    group = "autokuma";
    mode = "0600";

    sopsFile = ../../secrets/autokuma-matrix.toml.secret;
    format = "binary";
    restartUnits = [ "autokuma-local.service" ];
  };
}
