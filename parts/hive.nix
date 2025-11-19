{ self, inputs, ... }:

{
  flake.deploy.nodes.bart-server = {
    hostname = "bartoostveen.nl";
    profiles.system = {
      user = "root";
      sshUser = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.bart-server;
    };
  };

  flake.checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
