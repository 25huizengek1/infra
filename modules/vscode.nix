{ pkgs, lib, ... }:

{
  systemd.user.services.vscode-tunnel = {
    description = "Visual Studio Code tunnel";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${lib.getExe pkgs.vscode-fhs} tunnel --accept-server-license-terms
    '';
    path = with pkgs; [
      git
      nixd
      nixfmt-rfc-style
      ripgrep
    ];
    serviceConfig = {
      WorkingDirectory = "/root/infra";
      User = "root";
      Group = "users";
      Restart = "always";
    };
  };
}
