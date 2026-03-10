{ inputs, ... }:

{
  imports = [ inputs.meshcoretomqtt.nixosModules.default ];

  services.mctomqtt = {
    enable = true;
    iata = "EUR";
    serialPorts = [ "/dev/ttyUSB0" ];
    defaults = {
      letsmesh-us.enable = false;
      letsmesh-eu.enable = true;
    };
  };
}
