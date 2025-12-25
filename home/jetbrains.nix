{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jetbrains-toolbox
    jetbrains.idea
    jetbrains.gateway
  ];
}
