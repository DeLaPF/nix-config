{ config, lib, pkgs, ... }:
let
  cfg = config.dev-envs;
in
{
  imports = [
    ./esp32.nix
    ./android.nix
  ];

  options = {
    dev-envs.enable = lib.mkEnableOption "Enable Dev Env Options/Configuration";
  };

  config = lib.mkIf cfg.enable {};
}
