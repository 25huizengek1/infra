{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  gradleJdks = builtins.listToAttrs (
    map (ver: lib.nameValuePair "JDK${toString ver}" "${pkgs.${"openjdk${toString ver}"}}") [
      8
      17
      21
    ]
  );
in
{
  imports = [
    ../alacritty.nix
    ../copyparty-fuse.nix
    ../common.nix
    ../gpg.nix
    ../jetbrains.nix
    ../plasma.nix
  ];

  common.gui = true;

  home = {
    packages = with pkgs; [
      openjdk25
      wrk

      (inputs.prismlauncher-nixpkgs.legacyPackages.x86_64-linux.prismlauncher.override {
        additionalPrograms = [ ffmpeg ];
        jdks = [
          graalvmPackages.graalvm-ce
          zulu8
          zulu17
          zulu
        ];
      })
    ];

    file = {
      ".gradle/gradle.properties".text = ''
        org.gradle.console=verbose
        org.gradle.daemon.idletimeout=3600000
        org.gradle.java.installations.fromEnv=${builtins.concatStringsSep "," (lib.attrNames gradleJdks)}
      '';
    };

    sessionVariables = {
      GRADLE_LOCAL_JAVA_HOME = "${pkgs.openjdk25}";
    }
    // gradleJdks;
  };
}
