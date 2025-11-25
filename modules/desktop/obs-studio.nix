{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-tuna
    ];

    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
  };
}
