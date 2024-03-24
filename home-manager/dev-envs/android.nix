{ config, lib, pkgs, ... }:
let
  cfg = config.dev-envs;
  buildToolsVersion = "34.0.0";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion "30.0.3" "28.0.3" ];
    cmdLineToolsVersion = "8.0";
    platformVersions = [ "34" "33" "29" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
  };
  androidSdk = androidComposition.androidsdk;
  pinnedJdk = pkgs.jdk17;
in
{
  imports = [];
  options.dev-envs = {
    android.enable = lib.mkEnableOption "Enable android config";
  };

  config = lib.mkIf (cfg.enable && cfg.android.enable) {
    nixpkgs = {
       config = {
         android_sdk.accept_license = true;
       };
    };

    home.packages = with pkgs; [
      androidSdk
      pinnedJdk
      flutter # TODO: possibly move to own module
    ];

    # Required solution described here: https://stackoverflow.com/questions/77174188/nixos-issues-with-flutter-run
    # Also required solution described here: https://discourse.nixos.org/t/problem-building-flutter-app-for-android/35593/2
    # TODO: manage variables myself in custom sourced file, since home-manager only allows sourcing once per session (a bit strange imo)
    home.sessionVariables = {
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
      JAVA_HOME = pinnedJdk;
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
    };
  };
}
