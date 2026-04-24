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

  reqLimitZoneName = "reqlimit";
  connLimitZoneName = "connlimit";
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
                  limit_req zone=${reqLimitZoneName} burst=20 nodelay;
                '';
              };
            }
          )
        );
      };
    });
  };
  config.services.nginx.commonHttpConfig = ''
    geo $whitelist {
      default 0;
      127.0.0.0/24 1;
      10.0.0.0/8 1;
    }

    map $whitelist $limit {
      0 $binary_remote_addr;
      1 "";
    }

    limit_conn_zone      $limit    zone=${connLimitZoneName}:10m;
    limit_conn           ${connLimitZoneName} 8;
    limit_conn_log_level warn;
    limit_conn_status    503;

    limit_req_zone $limit zone=${reqLimitZoneName}:10m rate=10r/s;
    limit_req_log_level warn;
    limit_req_status     503;
  '';
}
