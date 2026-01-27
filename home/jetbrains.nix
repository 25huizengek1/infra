{ stablePkgs, ... }:

{
  home.packages = with stablePkgs; [
    jetbrains-toolbox
    jetbrains.idea
    jetbrains.gateway
  ];
}
