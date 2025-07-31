{
  description = "Bart Oostveen's Nix server infra configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    srvos = {
      url = "github:numtide/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    headplane = {
      url = "github:tale/headplane/44577aff81b5256d03940052e73783536d04151c";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nuschtos-search = {
      url = "github:NuschtOS/search";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-podman-stacks = {
      url = "github:Tarow/nix-podman-stacks";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.sops-nix.follows = "sops-nix";
    };

    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      import-tree,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./parts);
}
