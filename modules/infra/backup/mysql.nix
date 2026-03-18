{ config, lib, ... }:

let
  cfg = config.infra.backup.mysql;

  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkOption
    ;

  inherit (types) listOf str;
in
{
  options.infra.backup.mysql = {
    enable = mkEnableOption "Automatic mysql backups";
    jobName = mkOption {
      description = "Name of the borg backup job for mysql";
      type = str;
      default = "mysql";
      example = "state";
    };
    databases = mkOption {
      description = "List of all databases to backup";
      type = listOf str;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.mysql.enable;
        message = "You should not enable mysql backups when mysql is not enabled!";
      }
    ];

    infra.backup.mysql.databases = config.services.mysql.ensureDatabases;

    services.mysqlBackup = {
      enable = true;
      compressionAlg = "zstd";
      inherit (cfg) databases;
    };

    infra.backup.jobs.${cfg.jobName} = {
      paths = [ config.services.mysqlBackup.location ];
      wantedUnits = [ "mysql-backup.service" ];
    };

    systemd.timers.mysql-backup.enable = false;
  };
}
