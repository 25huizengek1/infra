{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    getExe
    types
    optional
    mkIf
    ;

  inherit (types)
    nullOr
    path
    ;

  cfg = config.services.mautrix-telegram-go;

  settingsFormat = pkgs.formats.yaml { };
  settingsFile = settingsFormat.generate "mautrix-telegram.yaml" cfg.settings;
  runtimeSettingsFile = "${cfg.dataDir}/config.yaml";
in
{
  options.services.mautrix-telegram-go = {
    enable = mkEnableOption "Mautrix-Telegram, a Matrix-Telegram hybrid puppeting/relaybot bridge";
    package = mkPackageOption pkgs "mautrix-telegram-go" { };
    setupPostgres = mkEnableOption "setting up a PostgreSQL database for mautrix-telegram";

    dataDir = mkOption {
      description = "Data directory that stores files like registration.yaml for mautrix-telegram";
      type = path;
      default = "/var/lib/mautrix-telegram";
      example = "/path/to/mautrix-telegram/data";
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = ''
        {file}`config.yaml` configuration as a Nix attribute set.
        Configuration options should match those described in
        [example-config.yaml](https://github.com/mautrix/telegram/blob/main/pkg/connector/example-config.yaml).

        Secret tokens should be specified using {option}`environmentFile`
        instead of this world-readable attribute set.
      '';
    };

    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing environment variables to be passed to the mautrix-telegram service,
        in which secret tokens can be specified securely.

        Set {option}`settings.env_config_prefix` for this environment file to be loaded by
        mautrix-telegram. This is the prefix for environment variables. All variables with
        this prefix must map to valid config fields. Nesting in variable names is
        represented with a dot (.). If there are no dots in the name, two underscores (__)
        are replaced with a dot. e.g. if the prefix is set to `BRIDGE_`, then
        `BRIDGE_APPSERVICE__AS_TOKEN` will set appservice.as_token. `BRIDGE_appservice.as_token`
        would work as well, but can't be set in a shell as easily.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.postgresql = mkIf cfg.setupPostgres {
      ensureUsers = [
        {
          name = "mautrix-telegram";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ "mautrix-telegram" ];
    };

    services.mautrix-telegram-go.settings.database = mkIf cfg.setupPostgres {
      type = "postgres";
      uri = "postgres:///mautrix-telegram?host=/var/run/postgresql";
    };

    users.users.mautrix-telegram = {
      isSystemUser = true;
      group = "mautrix-telegram";
      home = cfg.dataDir;
      description = "Mautrix-Telegram bridge user";
    };
    users.groups.mautrix-telegram = { };

    systemd.services.mautrix-telegram = {
      description = "Mautrix-Telegram, a Matrix-Telegram hybrid puppeting/relaybot bridge.";
      wantedBy = [ "multi-user.target" ];
      requires = optional cfg.setupPostgres "postgresql.target";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [
        lottieconverter
        ffmpeg-headless
      ];
      preStart = ''
        cp ${settingsFile} ${runtimeSettingsFile}
        chmod 660 ${runtimeSettingsFile}
      '';
      serviceConfig = {
        User = "mautrix-telegram";
        Group = "mautrix-telegram";
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "30s";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "mautrix-telegram";
        UMask = "0027";
        EnvironmentFile = cfg.environmentFile;
        ExecStart = "${getExe cfg.package} --config='${runtimeSettingsFile}'";
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        ProtectKernelLogs = true;
        ProtectKernelTunables = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        PrivateUsers = true;
        ProtectClock = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "@system-service";
      };
    };
  };
}
