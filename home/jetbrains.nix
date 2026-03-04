{ stablePkgs, ... }:

{
  home.packages = with stablePkgs; [
    jetbrains-toolbox
    jetbrains.idea
    jetbrains.gateway
    jetbrains.pycharm
    jetbrains.clion
  ];
}
