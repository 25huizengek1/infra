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

  cfg = config.services.mautrix-discord-go;

  settingsFormat = pkgs.formats.yaml { };
  settingsFile = settingsFormat.generate "mautrix-discord.yaml" cfg.settings;
  runtimeSettingsFile = "${cfg.dataDir}/config.yaml";
in
{
  options.services.mautrix-discord-go = {
    enable = mkEnableOption "Mautrix-Discord, a Matrix-Discord hybrid puppeting/relaybot bridge";
    package = mkPackageOption pkgs "mautrix-discord" { };
    setupPostgres = mkEnableOption "setting up a PostgreSQL database for mautrix-discord";

    dataDir = mkOption {
      description = "Data directory that stores files like registration.yaml for mautrix-discord";
      type = path;
      default = "/var/lib/mautrix-discord";
      example = "/path/to/mautrix-discord/data";
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = ''
        {file}`config.yaml` configuration as a Nix attribute set.
        Configuration options should match those described in
        [example-config.yaml](https://github.com/mautrix/discord/blob/main/pkg/connector/example-config.yaml).

        Secret tokens should be specified using {option}`environmentFile`
        instead of this world-readable attribute set.
      '';
    };

    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing environment variables to be passed to the mautrix-discord service,
        in which secret tokens can be specified securely.

        Set env_config_prefix in settings for this environment file to be loaded by
        mautrix-discord. This is the prefix for environment variables. All variables with
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
          name = "mautrix-discord";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ "mautrix-discord" ];
    };

    services.mautrix-discord-go.settings.appservice.database = mkIf cfg.setupPostgres {
      type = "postgres";
      uri = "postgres:///mautrix-discord?host=/var/run/postgresql";
    };

    users.users.mautrix-discord = {
      isSystemUser = true;
      group = "mautrix-discord";
      home = cfg.dataDir;
      description = "Mautrix-discord bridge user";
    };
    users.groups.mautrix-discord = { };

    systemd.services.mautrix-discord = {
      description = "Mautrix-Discord, a Matrix-Discord hybrid puppeting/relaybot bridge.";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      requires = optional cfg.setupPostgres "postgresql.target";
      path = with pkgs; [
        lottieconverter
        ffmpeg-headless
        envsubst
      ];
      preStart = ''
        # cp ${settingsFile} ${runtimeSettingsFile}
        # TODO: remove once mautrix-discord supports this properly
        envsubst -i ${settingsFile} -o ${runtimeSettingsFile}
        chmod 660 ${runtimeSettingsFile}
      '';
      serviceConfig = {
        User = "mautrix-discord";
        Group = "mautrix-discord";
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "30s";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "mautrix-discord";
        UMask = "0027";
        EnvironmentFile = cfg.environmentFile;
        ExecStart = "${getExe cfg.package} --config='${runtimeSettingsFile}'";
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
