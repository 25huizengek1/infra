{ lib, config, ... }:

let
  inherit (lib) mkIf genAttrs;
  cfg = config.infra.matrix;

  cinnies = genAttrs cfg.cinny.domains (_: {
    enableACME = true;
    forceSSL = true;

    locations."/".root = "${cfg.cinny.package}";
  });
in
{
  config = mkIf (cfg.enable && cfg.cinny.enable) {
    services.nginx.virtualHosts = {
      ${cfg.domain} = mkIf cfg.cinny.replaceContinuwuity {
        locations."/".root = "${cfg.cinny.package}";
      };
    }
    // cinnies;
  };
}
