{
  self,
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    mapAttrs
    recursiveUpdate
    genAttrs'
    nameValuePair
    ;
in
{
  flake.deploy.nodes =
    recursiveUpdate
      (genAttrs' self.home (
        {
          hostname,
          ip ? hostname,
          username,
          sshUser ? username,
          arch,
          ...
        }:
        nameValuePair hostname {
          hostname = ip;

          profiles.${username} = {
            user = username;
            inherit sshUser;

            path =
              inputs.deploy-rs.lib.${arch}.activate.home-manager
                self.homeConfigurations."${username}@${hostname}";
          };
        }
      ))
      (
        mapAttrs (
          name:
          {
            username,
            arch,
            ...
          }@c:

          let
            hostname = c.ip or c.hostname or name;
          in
          {
            inherit hostname;

            profiles.system = {
              user = username;
              sshUser = username;
              path = inputs.deploy-rs.lib.${arch}.activate.nixos self.nixosConfigurations.${name};
            };
          }
        ) self.nixos
      );

  flake.checks = builtins.mapAttrs (
    _system: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
