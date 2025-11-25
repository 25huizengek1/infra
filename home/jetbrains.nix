{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jetbrains-toolbox
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    jetbrains.gateway
    jetbrains.datagrip
  ];
}
