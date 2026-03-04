{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.common;
  inherit (builtins) fromJSON readFile;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  options.common = {
    gui = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Whether to add gui packages";
    };
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    home = {
      stateVersion = "26.05";

      sessionVariables = {
        EDITOR = "nano";
        SDL_VIDEODRIVER = "wayland";
      };

      shellAliases = {
        cat = "bat";
      };

      packages =
        with pkgs;
        [
          bat
          btop
          curl
          local.dawn
          dust
          ffmpeg
          forgejo-cli
          gh
          glab
          gopass
          inputs.licenseit.packages.${pkgs.stdenv.system}.default
          invoice
          jq
          meteor-git
          nano
          nix-init
          nurl
          ripgrep
          tomlq
          unzip
          wget
          zip
        ]
        ++ lib.optionals cfg.gui [
          discord
          element-desktop
          kdePackages.kate
          keystore-explorer
          libreoffice
          localsend
          mpv
          nerd-fonts.jetbrains-mono
          obsidian
          pavucontrol
          pdfarranger
          signal-desktop
          teams-for-linux
          telegram-desktop
          thunderbird
          vlc
          wl-clipboard
        ];
    };

    xdg.configFile = {
      "gh-dash/config.yml".source = ./gh-dash.yml;
      "google-chrome/NativeMessagingHosts" = lib.mkIf cfg.gui {
        source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts";
        recursive = true;
      };
    };

    fonts.fontconfig.enable = true;

    programs.home-manager.enable = true;

    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      settings = fromJSON (readFile ./oh-my-posh.json);
    };

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      config.hide_env_diff = true;
    };

    programs.google-chrome.enable = lib.mkDefault cfg.gui;
    programs.vscode.enable = lib.mkDefault cfg.gui;

    programs.yt-dlp = {
      enable = true;
      settings.sponsorblock-mark = "all,-preview";
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;
      historyControl = [ "erasedups" ];
      sessionVariables.PROMPT_COMMAND = "history -a; history -n";
    };

    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };
}
