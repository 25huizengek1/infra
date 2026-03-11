{ inputs, ... }:

{
  imports = [ inputs.meshcoretomqtt.nixosModules.default ];

  services.mctomqtt = {
    enable = true;
    iata = "ENS";
    serialPorts = [ "/dev/ttyACM0" ];
    defaults = {
      letsmesh-us.enable = false;
      letsmesh-eu.enable = true;
    };
  };
}
