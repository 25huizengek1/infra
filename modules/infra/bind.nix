{ inputs, lib, pkgs, ... }:

let
  inherit (lib)
    # keep-sorted start
    attrNames
    filterAttrs
    genAttrs'
    hasSuffix
    nameValuePair
    removeSuffix
    # keep-sorted end
    ;

  checkZone = zone: file: pkgs.runCommand "${zone}-checked" { } ''
    ${lib.getExe' pkgs.bind "named-checkzone"} ${zone} ${file}
    cp ${file} $out
  '';
in
{
  services.bind = {
    enable = true;
    zones =
      genAttrs'
        (attrNames (
          filterAttrs (name: value: value == "regular" && hasSuffix ".zone" name) (
            builtins.readDir inputs.dns-zones
          )
        ))
        (
          name:
          let
            zone = removeSuffix ".zone" name;
          in
          nameValuePair zone {
            master = true;
            file = "${checkZone zone "${inputs.dns-zones}/${name}"}";
          }
        );
  };

  networking.firewall.allowedUDPPorts = [ 53 ];
}
