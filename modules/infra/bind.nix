{ inputs, lib, ... }:

let
  inherit (lib)
    # keep-sorted start
    attrNames
    filterAttrs
    genAttrs'
    nameValuePair
    removeSuffix
    hasSuffix
    # keep-sorted end
    ;
in
{
  services.bind = {
    enable = true;
    zones =
      genAttrs'
        (
          attrNames (
            filterAttrs (name: value: value == "regular" && hasSuffix ".zone" name) (builtins.readDir inputs.dns-zones)
          )
        )
        (
          name:
          nameValuePair (removeSuffix ".zone" name) {
            master = true;
            file = "${inputs.dns-zones}/${name}";
          }
        );
  };
}
