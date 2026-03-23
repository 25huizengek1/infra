{ inputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.mixins-telegraf
  ];

  services.prometheus.exporters = {
    node.enable = true;
  };
}
