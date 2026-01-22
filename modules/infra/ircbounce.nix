{ config, lib, ... }:

let
  inherit (lib) genAttrs;

  vHost = "ircbounce.bartoostveen.nl";
  certDir = config.security.acme.certs.${vHost}.directory;
  cert = "${certDir}/cert.pem";
  key = "${certDir}/key.pem";
  dhParams = "${config.security.dhparams.path}/nginx.pem";
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

      LoadModule = [
        "adminlog"
        "fail2ban"
        "lastseen"
        "log"
        "notify_connect"
        "saslplainauth"
        "webadmin"
      ];
      User.bart = {
        Admin = true;
        AutoClearChanBuffer = false;
        AutoClearQueryBuffer = false;
        Buffer = 1000;
        QuitMsg = "Quit";
        RealName = "Bart";

        Pass.password = {
          Method = "sha256";
          Hash = "23fe43fd6af0c309ba2eb51094bbf4bc3170cff996fe5424189224b8234a8cca";
          Salt = "5aW1!NMlI_ZB:/4eLuv2";
        };
        Network.ircnet = {
          Server = "openirc.snt.utwente.nl 6667";
          Chan = genAttrs [ "#snt" ] (_name: {
            Buffer = 1000;
          });
          Nick = "bart_irc";
          LoadModule = [
            "savebuff"
          ];
          RealName = "Bart Oostveen";
        };
        Network.libera = {
          Server = "irc.eu.libera.chat +6697";
          Chan =
            genAttrs
              [
                "#libera"
                "#nixos"
                "#nixos-dev"
                "#nixos-chat"
              ]
              (_name: {
                Buffer = 1000;
              });
          LoadModule = [
            "sasl"
            "savebuff"
          ];
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
