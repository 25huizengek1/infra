{ inputs, lib, ... }:

{
  imports = [
    inputs.srvos.nixosModules.roles-nix-remote-builder
  ];

  roles.nix-remote-builder.schedulerPublicKeys = [ (lib.readFile ./remotebuild.pub) ];

  users.users.nix-remote-builder = {
    createHome = false;
    openssh.authorizedKeys = {
      keyFiles = [ ./remotebuild.pub ];
      keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiKac8QlzcnCMtTtFe39wW2lV884Oj+tlOz+9JgSAFl" ];
    };
  };

  nix = {
    nrBuildUsers = 64;
    settings = {
      min-free = 10 * 1024 * 1024;
      max-free = 200 * 1024 * 1024;
      max-jobs = "auto";
      cores = 0;
    };
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryMax = "90%";
    OOMScoreAdjust = 500;
  };
}
