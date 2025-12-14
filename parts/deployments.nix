{
  flake.nixos = {
    bart-server.sshUser = "root";
    # bart-laptop.sshUser = "bart";
    bart-laptop-new.sshUser = "bart";
    # bart-pc.sshUser = "bart";
  };

  flake.extraNixOSConfigurations = {
    installer = { };
    minimal-sd = { };
  };

  flake.home = [
    # {
    #   username = "bart";
    #   hostname = "bart-laptop";
    # }
    {
      username = "bart";
      hostname = "bart-laptop-new";
    }
    # {
    #   username = "bart";
    #   hostname = "bart-pc";
    # }
  ];
}
