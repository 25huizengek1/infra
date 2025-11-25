{ pkgs, ... }:

{
  security.rtkit.enable = true;
  security.sudo =
    let
      minutes = 60;
    in
    {
      enable = true;
      configFile = ''
        Defaults timestamp_timeout=${toString minutes}
      '';
      extraRules = [
        {
          commands = [
            {
              command = "${pkgs.systemd}/bin/systemctl suspend";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/reboot";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/poweroff";
              options = [ "NOPASSWD" ];
            }
          ];
          groups = [ "wheel" ];
        }
      ];
    };
}
