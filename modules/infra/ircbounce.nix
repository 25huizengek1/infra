{ config, lib, ... }:

let
  inherit (lib) genAttrs;

  vHost = "ircbounce.bartoostveen.nl";
  certDir = config.security.acme.certs.${vHost}.directory;
  cert = "${certDir}/cert.pem";
  key = "${certDir}/key.pem";
  dhParams = "${config.security.dhparams.path}/nginx.pem";

  channels = [ "#snt" ];
in
{
  services.nginx.virtualHosts.${vHost} = {
    enableACME = true;
    forceSSL = true;
  };

  services.znc = {
    enable = true;
    mutable = false;
    useLegacyConfig = false;
    openFirewall = false;
    config = {
      SSLCertFile = cert;
      SSLKeyFile = key;
      SSLDHParamFile = dhParams;

      LoadModule = [ "adminlog" ];
      User.bart = {
        Admin = true;
        Pass.password = {
          Method = "sha256";
          Hash = "23fe43fd6af0c309ba2eb51094bbf4bc3170cff996fe5424189224b8234a8cca";
          Salt = "5aW1!NMlI_ZB:/4eLuv2";
        };
        Network.ircnet = {
          Server = "openirc.snt.utwente.nl 6667";
          Chan = genAttrs channels (_name: { });
          Nick = "bart_irc";
        };
      };
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    config.services.znc.config.Listener.l.Port
  ];

  users.users.znc.extraGroups = [ "nginx" ];

  systemd.services.znc.after = [ "acme-${vHost}.service" ];
}
