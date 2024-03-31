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
      python3
      python3.pkgs.pip
      # Enables installing required python packages with pip (like `pyserial` for esptool)
      # Store requirements in `requirements.txt`
      # Create virtualenv: `virtualenv .venv`
      # Enter virtualenv: `source .venv/bin/activate`
      # Install requirements : `pip install -r requirements.txt`
      # Leave virtualenv: `deactivate`
      python3.pkgs.virtualenv
    ];

    home.file.".config/arduino-cli/config.yaml".text = ''
      additional_urls:
        - https://dl.espressif.com/dl/package_esp32_index.json
      board_manager:
        additional_urls:
          - https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
    '';

    dev-envs.shellHelpers =
    let
      HOME = "\${HOME}";
      ARDUINO_CONFIG = "\${ARDUINO_CONFIG}";
    in
    [
      ''
        # Esp32 Dev Env
        export ARDUINO_CONFIG=${HOME}/.config/arduino-cli/config.yaml;
        alias ardc='arduino-cli $@ --config-file "${ARDUINO_CONFIG}"';
      ''
    ];
  };
}
