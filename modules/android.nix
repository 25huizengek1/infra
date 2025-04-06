{ pkgs, ... }:

let
  android = pkgs.androidenv.composeAndroidPackages { };
in
{
  environment.systemPackages = [
    pkgs.fdroidserver
    android.androidsdk
  ];

  # TODO: systemd service for fdroid, maybe add Vagrant (as F-Droid recommends), or put it into an (OCI) container
}
