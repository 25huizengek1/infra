{ ... }:

let
  domain = (import ../const.nix).domain;
in {
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "anubis" ];
  services.anubis.defaultOptions.settings = {
    DIFFICULTY = 4;
    SERVE_ROBOTS_TXT = true;
    WEBMASTER_EMAIL = "anubis@${domain}";
  };
}
