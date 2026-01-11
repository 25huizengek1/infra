{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    # keep-sorted start
    attrNames
    filterAttrs
    genAttrs'
    hasSuffix
    nameValuePair
    range
    removeSuffix
    # keep-sorted end
    ;

  nameServers = range 2 5;

  # TODO: dnssec
  extraOptions = '''';

  zoneFiles = attrNames (
    filterAttrs (name: value: value == "regular" && hasSuffix ".zone" name) (
      builtins.readDir inputs.dns-zones
    )
  );

  checkZone =
    zone: file:
    pkgs.runCommand "${zone}-checked" { } ''
      ${lib.getExe' pkgs.bind "named-checkzone"} ${zone} ${file}
      cp ${file} $out
    '';

  toZoneName = removeSuffix ".zone";

  nat = n: "fc00::${toString n}";
in
{
  services.bind = {
    enable = true;
    inherit extraOptions;

    zones = genAttrs' zoneFiles (
      name:
      let
        zone = toZoneName name;
      in
      nameValuePair zone {
        master = true;
        slaves = [ "localnets" ];
        file = "${checkZone zone "${inputs.dns-zones}/${name}"}";
      }
    );
  };

  networking.firewall.allowedUDPPorts = [ 53 ];

  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;

  networking.interfaces.enp1s0.ipv6.routes = map (x: {
    address = "2a01:4f8:c2c:2f66::${toString x}";
    prefixLength = 128;
    via = nat x;
  }) nameServers;

  # TODO: generalize such that these containers can run 'anywhere' and be routed through Tailscale or smth
  #       (since they now all run on the same host)
  # DNS slaves that both keep track of ns1 and are slave to other people
  # TODO: generate bind config from config file in dns ring repo
  containers = genAttrs' nameServers (
    x:
    nameValuePair "bind-ns${toString x}" {
      autoStart = true;
      privateNetwork = true;

      hostAddress6 = nat 1;
      localAddress6 = nat x;

      config =
        { config, ... }:

        {
          networking = {
            hostName = "ns${toString x}";
            useHostResolvConf = true;

            interfaces.eth0.ipv6.addresses = [
              {
                address = "2a01:4f8:c2c:2f66::${toString x}";
                prefixLength = 128;
              }
            ];

            firewall.allowedUDPPorts = [ 53 ];
          };

          services.bind = {
            enable = true;
            inherit extraOptions;
            zones = genAttrs' zoneFiles (
              name:
              let
                zone = toZoneName name;
              in
              nameValuePair zone {
                master = false;
                masters = [ (nat 1) ];
                file = "${config.services.bind.directory}/${name}";
              }
            );
          };

          system.stateVersion = "26.05";
        };
    }
  );
}
