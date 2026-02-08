{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    clock24 = true;
    secureSocket = true;
    reverseSplit = true;
    baseIndex = 1;
    tmuxinator.enable = true;
    tmuxp.enable = true;

    extraConfig = ''
      set -g automatic-rename on
      set -g allow-rename on
      set -g set-titles on

      set -g window-status-format "#I:#(basename #{pane_current_command})"
      set -g window-status-current-format "#[bold]#I:#(basename #{pane_current_command})"
    '';

    plugins = with pkgs.tmuxPlugins; [
      cpu
      battery
      {
        plugin = tmux-sessionx;
        extraConfig = ''
          set -g @sessionx-bind '<prefix>+o'
        '';
      }
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
        '';
      }
      {
        plugin = mkTmuxPlugin {
          pluginName = "tmux-statusline-themes";
          version = "unstable";
          src = pkgs.fetchFromGitHub {
            owner = "dmitry-kabanov";
            repo = "tmux-statusline-themes";
            rev = "5239a3b8d0de860ef573a688678c64a47d3d431f";
            hash = "sha256-A4PxrkUGZHjIt0np95848quUo42i+4CX9LwOJ5ek0/Y=";
          };
        };
        extraConfig = ''
          set -g @tmux-statusline-theme 'solarized-dark'
        '';
      }
      tmux-which-key
    ];
  };
}
