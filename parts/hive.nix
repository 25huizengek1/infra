{
  self,
  inputs,
  lib,
  ...
}:

{
  flake.deploy.nodes = lib.mapAttrs (_name: nixos: {
    hostname = nixos.config.networking.hostName;

    profiles.system = {
      user = "root";
      sshUser = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixos;
    };
  }) self.nixosConfigurations;

  flake.checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
