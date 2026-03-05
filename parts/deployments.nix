{
  deployments = {
    nixos = {
      bart-server.sshUser = "root";
      bart-laptop-new.sshUser = "bart";
      atlas = {
        sshUser = "root";
        system = "aarch64-linux";
      };
      # bart-pc.sshUser = "bart";
    };

    extraNixOSConfigurations = {
      installer = { };
      minimal-sd = { };
    };

    home = [
      {
        username = "bart";
        hostname = "bart-laptop-new";
      }
      # {
      #   username = "bart";
      #   hostname = "bart-pc";
      # }
    ];
  };
}
