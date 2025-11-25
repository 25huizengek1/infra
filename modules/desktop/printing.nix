{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    browsed.enable = true;
    defaultShared = true;
    openFirewall = true;
    drivers = [ pkgs.hplip ];
    cups-pdf.enable = true;
  };

  services.system-config-printer.enable = true;
  programs.system-config-printer.enable = true;

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      hplip
      sane-airscan
      ipp-usb
    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.skanpage
  ];
}
