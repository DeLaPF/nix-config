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
    dev-envs.shellHelpers = lib.mkOption {
      type = lib.types.listOf lib.types.lines;
      default = [];
      example = [
        ''
          One set of shell helpers
        ''
        ''
          Another set of shell helpers
        ''
      ];
      description = ''
        Define additional shell helpers that will be combined into a single posix file,
        able to be sourced by any posix compatible shell.
        See the example for more info.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/.shellHelpers".text = ''
      #!/usr/bin/env bash
      ${lib.strings.concatMapStrings (x: "\n" + x) cfg.shellHelpers}
    '';
  };
}
