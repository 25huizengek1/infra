{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
    mkIf
    mkAfter
    ;

  inherit (types)
    attrsOf
    submodule
    bool
    ;
in
{
  options.services.nginx.virtualHosts = mkOption {
    type = attrsOf (submodule {
      options.locations = mkOption {
        type = attrsOf (
          submodule (
            { config, ... }:
            {
              options.rateLimit = mkOption {
                type = bool;
                default = true;
                description = "Enable global rate limiting for this location.";
              };

              config = mkIf config.rateLimit {
                extraConfig = mkAfter ''
                  limit_req zone=zone burst=20 nodelay;
                '';
              };
            }
          )
        );
      };
    });
  };
}
