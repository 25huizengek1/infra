{
  flake.nixos = {
    bart-server.username = "root";
    # bart-laptop.username = "bart";
    bart-laptop-new.username = "bart";
    bart-pc.username = "bart";
  };

  flake.extraNixOSConfigurations = {
    installer = {};
    minimal-sd = {};
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
    {
      username = "bart";
      hostname = "bart-pc";
    }
  ];
}
