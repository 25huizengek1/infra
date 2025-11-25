{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "euro";
    };
  };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.kdeconnect.enable = true;
}
