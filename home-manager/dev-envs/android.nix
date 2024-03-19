{ config, lib, pkgs, ... }:
let
  cfg = config.dev-envs;
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
      androidenv.androidPkgs_9_0.androidsdk
      android-tools
      flutter # TODO: possibly move to own module
    ];
  };
}
