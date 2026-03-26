{ pkgs, ... }:

{
  networking.networkmanager.enable = true;

  # programs.openvpn3.enable = true;
  networking.firewall.checkReversePath = "loose";
  # networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  environment.systemPackages = with pkgs; [ eduvpn-client ];
}
