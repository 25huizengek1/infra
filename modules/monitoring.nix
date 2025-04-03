{ pkgs, ... }:

{
  services.grafana = {
    enable = true;
    settings.server =
      let
        domain = "grafana.omeduostuurcentenneef.nl";
      in
      {
        inherit domain;
        root_url = "https://${domain}";
        protocol = "socket";
      };
  };

  services.prometheus = {
    enable = true;
    port = 7070;
    extraFlags = [
      "--web.external-url=https://prometheus.omeduostuurcentenneef.nl/"
    ];
    globalConfig.scrape_interval = "15s";

    ruleFiles = [
      (pkgs.writeText "up.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "up";
              rules = [
                {
                  alert = "NotUp";
                  expr = ''
                    up == 0
                  '';
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];
}
