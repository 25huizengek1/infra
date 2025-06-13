{
  perSystem =
    { pkgs, ... }:
    {
      apps.deploy = {
        type = "app";

        program = pkgs.writeShellApplication {
          name = "deploy.sh";
          runtimeInputs = with pkgs; [ nixos-anywhere ];
          text = ''
            nixos-anywhere \
              --generate-hardware-config nixos-facter ./machines/bart-server.json \
              --flake .#bart-server \
              --target-host root@78.46.150.107
          '';
        };

        meta = {
          description = "Deploy NixOS configuration for bart-server to Hetzner";
          mainProgram = "deploy.sh";
        };
      };
    };
}
