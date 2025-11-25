{
  host ? "bart-pc",
  pkgs,
  lib,
  ...
}:

{
  networking = {
    hostName = host;
    networkmanager.enable = true;
  };

  services.tailscale.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.ip_unprivileged_port_start" = 0;
  };

  programs.openvpn3.enable = true;
  networking.firewall.checkReversePath = false;
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  system.activationScripts = {
    rfkillUnblockWlan = {
      text = ''
        rfkill unblock wlan
      '';
      deps = [ ];
    };
  };
}
