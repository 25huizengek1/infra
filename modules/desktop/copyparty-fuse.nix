{ pkgs, config, ... }:

{
  environment.systemPackages = [ pkgs.rclone ];

  fileSystems."/mnt/omeduoparty" = {
    device = "omeduoparty-dav:";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=${config.sops.secrets.omeduoparty-dav-mnt.path}"
    ];
  };

  sops.secrets.omeduoparty-dav-mnt = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../../secrets/non-infra/rclone-omeduoparty-mnt.conf.secret;
    format = "binary";
  };
}
