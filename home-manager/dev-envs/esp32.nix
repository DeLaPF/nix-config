{ config, lib, pkgs, ... }:
let
  cfg = config.dev-envs;
in
{
  imports = [];
  options.dev-envs = {
    esp32.enable = lib.mkEnableOption "Enable esp32 config";
  };

  config = lib.mkIf (cfg.enable && cfg.esp32.enable) {
    home.packages = with pkgs; [
      arduino-cli
    ];
  };
}
