{ config, pkgs, ... }:

let
  fqdn = "bartoostveen.nl";
  domain = "matrix.${fqdn}";
in
{
  services.matrix-continuwuity = {
    enable = true;
    settings.global = {
      server_name = fqdn;
      new_user_displayname_suffix = "";
      allow_registration = false;
      allow_encryption = true;
      allow_federation = true;
      trusted_servers = [ "matrix.org" ];

      address = null;
      unix_socket_path = "/run/continuwuity/continuwuity.sock";
      unix_socket_perms = 660;

      well_known = {
        client = "https://${domain}";
        server = "${domain}:443";
        support_email = "root@bartoostveen.nl";
      };
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [
    config.services.matrix-continuwuity.group
  ];

  services.nginx.virtualHosts =
    let
      socket = "http://unix://${config.services.matrix-continuwuity.settings.global.unix_socket_path}";
      cinny = pkgs.cinny.override {
        conf = {
          homeserverList = [ fqdn ];
          defaultHomeserver = 0;
          allowCustomHomeservers = false;
          featuredCommunities = { };
        };
      };
    in
    {
      ${fqdn}.locations."/.well-known/matrix/".proxyPass = socket;
      ${domain} = {
        enableACME = true;
        forceSSL = true;

        locations."/".root = "${cinny}";
        locations."/_matrix".proxyPass = socket;
      };
    };
}
