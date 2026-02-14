{
  pkgs,
  lib,
  ...
}:

{
  networking.networkmanager.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="tailscale0", RUN+="${lib.getExe' pkgs.iproute2 "ip"} link set dev tailscale0 mtu 1500"
  '';

  services.tailscale.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.ip_unprivileged_port_start" = 0;
  };

  programs.openvpn3.enable = true;
  networking.firewall.checkReversePath = false; # TODO: remove
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
}
