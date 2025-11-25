{ pkgs, ... }:

let
  android = pkgs.androidenv.composeAndroidPackages {
    includeNDK = true;
    buildToolsVersions = [ "36.0.0" ];
    platformVersions = [ "36" ];
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    includeEmulator = true;
  };
in
{
  programs.adb.enable = true;

  environment.systemPackages = [
    (pkgs.android-studio.withSdk android.androidsdk)
    (pkgs.androidStudioPackages.canary.withSdk android.androidsdk)
    android.androidsdk
  ];
}
