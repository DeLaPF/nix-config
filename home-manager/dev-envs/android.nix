{ config, lib, pkgs, ... }:
let
  cfg = config.dev-envs;
  buildToolsVersion = "34.0.0";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion "28.0.3" ];
    cmdLineToolsVersion = "8.0";
    platformVersions = [ "34" "29" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
  };
  androidSdk = androidComposition.androidsdk;
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
      jdk17
      flutter # TODO: possibly move to own module
    ];

    home.sessionVariables = {
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    };
  };
}
