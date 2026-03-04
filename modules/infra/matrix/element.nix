{ config, lib, ... }:

let
  cfg = config.infra.matrix;

  inherit (lib) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.element.enable) {
    services.nginx.virtualHosts.${cfg.element.domain} = {
      enableACME = true;
      forceSSL = true;

      locations."/".root = "${cfg.element.package}";
    };
  };
}
