{
  self,
  inputs,
  lib,
  config,
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
      (genAttrs' config.deployments.home (
        {
          hostname,
          ip ? null,
          username,
          sshUser ? null,
          arch,
          ...
        }:
        nameValuePair hostname {
          hostname = if ip != null then ip else hostname;

          profiles.${username} = {
            user = username;
            sshUser = if sshUser != null then sshUser else username;

            interactiveSudo = username == "root" && sshUser != "root";

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
            ip ? null,
            hostname ? null,
            sshUser ? null,
            username,
            arch,
            ...
          }:

          let
            h =
              if ip != null then
                ip
              else if hostname != null then
                hostname
              else
                name;
          in
          {
            hostname = h;

            profiles.system = {
              user = username;
              sshUser = if sshUser != null then sshUser else username;

              interactiveSudo = username == "root" && sshUser != "root";

              path = inputs.deploy-rs.lib.${arch}.activate.nixos self.nixosConfigurations.${name};
            };
          }
        ) config.deployments.nixos
      );

  flake.checks = builtins.mapAttrs (
    _system: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
