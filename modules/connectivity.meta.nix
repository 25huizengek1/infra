{ lib, ... }:

let
  inherit (lib)
    splitString
    ;
  first = list: builtins.elemAt list 0;
in
rec {
  _hosts = {
    bart-server = [
      "78.46.150.107/32"
      "2a01:4f8:c2c:2f66::1/128"
    ];
    vector = [
      "46.225.142.85/32"
      "2a01:4f8:1c19:1cd2::1/128"
    ];
  };

  allRanges = builtins.attrValues _hosts |> builtins.concatLists;
  rangesFor = host: if _hosts ? "${host}" then _hosts.${host} else [ ];
  ipsFor = host: rangesFor host |> map (range: range |> splitString "/" |> first);
}
