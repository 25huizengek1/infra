{ pkgs, lib, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [
        "${pkgs.alacritty-theme}/catppuccin_mocha.toml"
      ];
      window = {
        startup_mode = "Maximized";
        dynamic_title = true;
        dynamic_padding = true;
      };
      font = {
        normal = {
          family = "JetBrainsMonoNL Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMonoNL Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMonoNL Nerd Font";
          style = "Italic";
        };
      };
      cursor.style.shape = "Beam";
      env.TERM = "xterm-256color";
      terminal.shell = {
        program = lib.getExe pkgs.bashInteractive;
        args = [
          "-c"
          (lib.getExe pkgs.tmux)
        ];
      };
    };
  };
}
