{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jetbrains-toolbox
    jetbrains.idea-ultimate
    jetbrains.gateway
  ];
}
