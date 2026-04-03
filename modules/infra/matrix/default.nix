{ lib, pkgs, ... }:

{
  imports = [
    ./alertmanager.nix
    ./call.nix
    ./cinny.nix
    ./continuwuity.nix
    ./element.nix
    ./livekit.nix
    ./telegram.nix
  ];

  infra.matrix = {
    enable = true;
    fqdn = "bartoostveen.nl";
    domain = "matrix.bartoostveen.nl";
    livekit = {
      enable = true;
      domain = "matrix-rtc.bartoostveen.nl";
    };
    call = {
      enable = true;
      domain = "call.bartoostveen.nl";
    };
    element = {
      enable = true;
      domain = "element.bartoostveen.nl";
    };
    cinny = {
      enable = true;
      package = pkgs.cinny.override {
        conf = {
          homeserverList = [
            "bartoostveen.nl"
            "elisaado.com"
            "utwente.io"
            "matrix.org"
          ];
          defaultHomeserver = 0;
          allowCustomHomeservers = true;
          featuredCommunities = { };
          hashRouter.enabled = true;
        };
      };
      domains = map (n: "cinny${toString n}.bartoostveen.nl") (lib.range 0 9);
    };
  };
}
