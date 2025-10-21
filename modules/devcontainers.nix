{
  config,
  pkgs,
  lib,
  ...
}:

let
  domain = "omeduostuurcentenneef.nl";
  names = [
    "kamile"
    "jojo"
    "silvan"
  ];
  repo = "diamond-information-project";
  uid = 654321;
  extensions = with pkgs.nix-vscode-extensions.vscode-marketplace; [
    ms-python.vscode-pylance
    ms-python.python
    ms-toolsai.jupyter
    ms-vsliveshare.vsliveshare
  ];
  extensionsDir = pkgs.buildEnv {
    name = "vscode-extensions";
    paths = extensions ++ [
      (pkgs.writeTextFile {
        name = "vscode-extensions-json";
        destination = "/share/vscode/extensions/extensions.json";
        text = pkgs.vscode-utils.toExtensionJson extensions;
      })
    ];
  };
in
{
  systemd.tmpfiles.rules = lib.concatMap (name: [
    "d /srv/dev/${name} 0755 vscode vscode - -"
  ]) names;

  users.users.vscode = {
    isNormalUser = true;
    createHome = false;
    inherit uid;
  };
  users.groups.vscode = { };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp1s0";
    enableIPv6 = true;
  };

  containers = lib.genAttrs names (
    name:
    let
      index = lib.lists.findFirstIndex (n: n == name) null names;
    in
    {
      autoStart = true;

      privateNetwork = true;
      hostAddress = "10.233.${toString index}.1";
      localAddress = "10.233.${toString index}.2";
      hostAddress6 = "fc00::${toString index}:1";
      localAddress6 = "fc00::${toString index}:2";

      bindMounts = {
        "/srv/dev/${name}" = {
          hostPath = "/srv/dev/${name}";
          isReadOnly = false;
        };

        "/srv/${repo}/vscode-extensions" = {
          hostPath = "${extensionsDir}";
          isReadOnly = true;
        };

        "/srv/${repo}/connection-token" = {
          hostPath = config.sops.secrets.project-token.path;
          isReadOnly = true;
        };

        "/srv/${repo}/.env" = {
          hostPath = config.sops.secrets.project-env.path;
          isReadOnly = true;
        };
      };

      config =
        { config', pkgs, ... }:

        {
          services.openvscode-server = {
            enable = true;
            user = "vscode";
            host = "0.0.0.0";
            port = 3000;
            extensionsDir = "/srv/${repo}/vscode-extensions/share/vscode/extensions";
            connectionTokenFile = "/srv/${repo}/connection-token";
            telemetryLevel = "off";
          };

          users.users.vscode = {
            isNormalUser = true;
            home = "/home/vscode";
            createHome = true;
            inherit uid;
          };
          users.groups.vscode = { };

          systemd.services.initProject = {
            description = "Initialize project Git repo";
            after = [
              "network.target"
              "network-online.target"
            ];
            wants = [
              "network.target"
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "oneshot";
              User = "vscode";
              EnvironmentFile = "/srv/${repo}/.env";
              Restart = "on-failure";
            };

            path = with pkgs; [
              git
            ];

            script = ''
              pushd /srv/dev/${name}
              if [ ! -d .git ]; then
                ${lib.getExe pkgs.gh} repo clone 25huizengek1/${repo}
                pushd ${repo}
                ln -s .envrc.recommended .envrc
                ${lib.getExe pkgs.direnv} allow
                popd
              fi
              popd
            '';
          };

          programs.direnv = {
            enable = true;
            nix-direnv.enable = true;
          };

          environment.systemPackages = with pkgs; [
            git
            python3
          ];

          networking = {
            firewall.allowedTCPPorts = [
              3000
              8501
            ];
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;

          nixpkgs.config.allowUnfree = true;

          system.stateVersion = "25.11";
        };
    }
  );

  services.nginx.virtualHosts = lib.foldl' (
    acc: name:
    let
      ip = "10.233.${toString (lib.lists.findFirstIndex (n: n == name) null names)}.2";
    in
    acc
    // {
      "${name}.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${ip}:3000";
          proxyWebsockets = true;
        };
      };

      "${name}-test.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${ip}:8501";
          proxyWebsockets = true;
        };
      };
    }
  ) { } names;

  sops.secrets.project-env = {
    format = "binary";
    sopsFile = ../secrets/project-env.secret;

    owner = "vscode";
    group = "vscode";
    mode = "0660";
    restartUnits = map (n: "container@${n}.service") names;
  };

  sops.secrets.project-token = {
    format = "binary";
    sopsFile = ../secrets/project-token.secret;

    owner = "vscode";
    group = "vscode";
    mode = "0660";
    restartUnits = map (n: "container@${n}.service") names;
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "merge-${repo}" ''
      set -eux

      FINAL_REPO=/srv/${repo}
      NAME=$1
      SRC=/srv/dev/$NAME/${repo}

      pushd "$SRC"
      git add -A
      git commit -m "progress: $NAME" || true
      git push
      popd

      pushd "$FINAL_REPO"
      git add -A
      git stash || true
      git pull
      git stash pop || true
      popd

      for branch in ${lib.concatStringsSep " " names}; do
        pushd "/srv/dev/$branch/${repo}"
        git add -A
        git stash || true
        git pull
        git stash pop || true
        chown -R vscode:users .
        popd
      done

      pushd "$FINAL_REPO"
      git push || true
      popd
    '')
    (pkgs.writeShellScriptBin "pullall-${repo}" ''
      set -eux

      for branch in ${lib.concatStringsSep " " names}; do
        pushd "/srv/dev/$branch/${repo}"
        git add -A
        git stash || true
        git pull
        git stash pop || true
        chown -R vscode:users .
        popd
      done
    '')
  ];
}
