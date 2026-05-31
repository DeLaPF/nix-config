{ config, lib, pkgs, ... }:
let
  t = ''$(date --utc +"%Y-%m-%dT%H:%M:%SZ")'';
  formatError = msg: ''echo -e "\033[1;31mERROR:\033[0m ${msg} (${t})" >&2'';
  formatWarning = msg: ''echo -e "\033[1;33mWARNING:\033[0m ${msg} (${t})" >&2'';
  # "assert-${(baseNameOf path_str)}"
  assert_file = { path_str, msg, fatal }: pkgs.runCommand "file-assert" {} ''
    if [ ! -e "${path_str}" ]; then
      ${
        (if fatal then formatError else formatWarning)
        (if msg != "" then msg else "Missing file: ${path_str}")
      }
      ${if fatal then "exit 1" else ""}
    fi

    mkdir -p $out
    echo ${t} > $out/log
  '';
in
{
  options = {
    fileAssertions = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          path_str = lib.mkOption { type = lib.types.str; };
          msg = lib.mkOption { type = lib.types.str; default = ""; };
          fatal = lib.mkOption { type = lib.types.bool; default = true; };
        };
      });
      default = [];
    };
    extraSandboxPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = {
    system.checks = map (f: assert_file f) config.fileAssertions;

    nix.settings =
    let
      addPaths = (lib.unique (map (f: dirOf f.path_str) config.fileAssertions))
        ++ config.extraSandboxPaths;
    in
    {
      extra-sandbox-paths = builtins.trace
        "Adding [${lib.concatStringsSep ", " addPaths}] to extra-sandbox-paths"
        addPaths;
    };
  };
}
