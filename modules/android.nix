{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.fdroidserver
    pkgs.androidenv.composeAndroidPackages { }.all
  ];

  # TODO: systemd service for fdroid, maybe add Vagrant (as F-Droid recommends), or put it into an (OCI) container
}