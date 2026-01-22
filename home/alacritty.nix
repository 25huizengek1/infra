{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [
        "${pkgs.alacritty-theme}/catppuccin_mocha.toml"
      ];

      window = {
        opacity = 0.75;
        blur = true;
        startup_mode = "Maximized";
        dynamic_title = true;
      };

      font.normal = {
        family = "JetBrainsMonoNL Nerd Font";
        style = "Regular";
      };
    };
  };
}
