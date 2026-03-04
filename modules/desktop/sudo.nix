{ pkgs, lib, ... }:

let
  inherit (lib) getExe';
in
{
  security.rtkit.enable = true;

  security.sudo =
    let
      minutes = 60;
      commands = [
        "${getExe' pkgs.systemd "systemctl"} suspend"
        (getExe' pkgs.systemd "reboot")
        (getExe' pkgs.systemd "poweroff")
      ];
    in
    {
      enable = true;
      configFile = ''
        Defaults timestamp_timeout=${toString minutes}
      '';
      extraRules = [
        {
          commands = map (command: {
            inherit command;
            options = [ "NOPASSWD" ];
          }) commands;
          groups = [ "wheel" ];
        }
      ];
    };
}
