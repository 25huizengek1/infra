{
  pkgs,
  lib,
  ...
}:

{
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
  };

  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = with pkgs; [
      nixos-bgrt-plymouth
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];
  nix.channel.enable = lib.mkForce false;

  services.resolved.enable = true;

  environment.systemPackages = with pkgs; [
    age
    copyparty
    curl
    deploy-rs.deploy-rs
    file
    git
    nil
    nixd
    nix-inspect
    nix-output-monitor
    nixfmt-rfc-style
    sops
    wget
  ];

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 3d";
      dates = "weekly";
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libvirt
    ];
  };

  programs.nano = {
    enable = true;
    nanorc = ''
      set historylog
      set multibuffer
      set positionlog
      set locking

      set tabsize 4
      set tabstospaces

      set guidestripe 80
      set constantshow
      set linenumbers
      set mouse
      set indicator

      set afterends
      set zap
      set jumpyscrolling
      set smarthome

      set trimblanks
      set colonparsing

      set atblanks
      set softwrap

      extendsyntax nix formatter ${pkgs.nixfmt-rfc-style}
    '';
  };

  services.openssh = {
    enable = true;
    settings = {
      UseDns = true;
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };

  services.libinput.enable = true;
  services.flatpak.enable = true;
}
