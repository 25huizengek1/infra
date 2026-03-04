{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) getExe;
in
{
  systemd.services.alertmanager-matrix = {
    description = "Alertmanager Matrix bot";
    after = [
      "network.target"
      "continuwuity.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = getExe pkgs.local.alertmanager-matrix;
      EnvironmentFile = config.sops.secrets.alertmanager-matrix-env.path;
      Restart = "on-failure";
      DynamicUser = true;
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MountAPIVFS = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateUsers = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = "strict";
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = 27;
    };
  };

  sops.secrets.alertmanager-matrix-env = {
    sopsFile = ../../../secrets/alertmanager-matrix.env.secret;
    owner = "alertmanager-matrix";
    group = "alertmanager-matrix";
    format = "binary";
    mode = "440";
    restartUnits = [ "alertmanager-matrix.service" ];
  };
}
