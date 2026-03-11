{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    nameValuePair
    concatStringsSep
    splitString
    listToAttrs
    ;
in
{
  infra.autokuma.instances.local = mkIf config.infra.wireguard.enable {
    tags.wireguard = {
      name = "Wireguard";
      color = "#ffea00";
    };
    monitors =
      let
        inherit (import ../../../wireguard.meta.nix) nodes;
        first = list: builtins.elemAt list 0;
      in
      map (
        peer:
        nameValuePair "wireguard-${peer.name}" {
          type = "ping";
          name = "${peer.name} - Wireguard ping (${concatStringsSep ", " nodes.${peer.name}.ips})";
          description = "Managed by AutoKuma";
          timeout = 20;
          interval = 10;
          retry_interval = 10;
          packet_size = 56;
          notification_name_list = [ "autokuma-matrix" ];
          hostname = nodes.${peer.name}.ips |> first |> splitString "/" |> first;
          tag_names = [
            {
              name = "autokuma";
              value = "Wireguard";
            }
            {
              name = "wireguard";
              value = peer.name;
            }
          ];
        }
      ) (config.networking.wireguard.interfaces.${config.infra.wireguard.interface}.peers)
      |> listToAttrs;
  };
}
