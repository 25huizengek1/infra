{ config, lib, ... }:

{
  programs.rclone = {
    enable = lib.mkDefault true;
    remotes.omeduoparty-dav = {
      config = {
        type = "webdav";
        url = "https://fs.omeduostuurcentenneef.nl";
        vendor = "owncloud";
        user = "adm";
      };

      secrets.pass = config.sops.secrets.omeduoparty-pass.path;

      mounts."/" = {
        enable = true;
        mountPoint = "${config.home.homeDirectory}/omeduoparty";
        options = {
          poll-interval = "10s";
          umask = "002";
          vfs-cache-mode = "full";
        };
      };
    };
  };

  sops.secrets.omeduoparty-pass = {
    sopsFile = ./secrets/omeduoparty-pass.secret;
    format = "binary";
  };
}
