{ config, lib, ... }:

let
  cfg = config.infra.backup.postgres;

  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkOption
    singleton
    ;

  inherit (types) str;
in
{
  options.infra.backup.postgres = {
    enable = mkEnableOption "Automatic postgres backups";
    jobName = mkOption {
      description = "Name of the borg backup job for postgres";
      type = str;
      default = "postgres";
      example = "state";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.postgresql.enable;
        message = "You should not enable postgres backups when postgres is not enabled!";
      }
    ];

    services.postgresqlBackup = {
      enable = true;
      compression = "zstd";
      startAt = [ ];
    };
    infra.backup.jobs.${cfg.jobName} = {
      paths = [ "/var/backup/postgresql" ];
      wantedUnits =
        if config.services.postgresqlBackup.backupAll then
          singleton "postgresqlBackup.service"
        else
          map (db: "postgresqlBackup-${db}.service") config.services.postgresqlBackup.databases;
    };
  };
}
