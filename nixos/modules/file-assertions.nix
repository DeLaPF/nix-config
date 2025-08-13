{ config, lib, pkgs, ... }:
let
  formatError = msg: ''echo -e "\033[1;31mERROR:\033[0m ${msg}" >&2'';
  # NOTE: ESC must be used (typed with ctrl+v ESC (ascii 27))
  formatWarning = msg: builtins.trace "[1;33mWARNING:[0m ${msg}" "echo ''";

  assert_file = { path_str, msg, fatal }: pkgs.stdenv.mkDerivation {
    name = "assert-${(baseNameOf path_str)}";
    phases = [ "buildPhase" "installPhase" ];
    # TODO: `fatal` doesn't quite work as a it seems that the nix functions are always evaluated regardless if the condition is met
    # this should have been obvious, though it does make emitting a proper warning more difficult (and thus todo)
    # it may just have to be that fatal is not an option since we can only reliable emit message on "fatal" error
    buildPhase = ''
      if [ ! -e "${path_str}" ]; then
        ${
          (if fatal then formatError else formatWarning)
          (if msg != "" then msg else "Missing file: ${path_str}")
        }
        ${if fatal then "exit 1" else ""}
      fi
    '';
    installPhase = "mkdir -p $out";
  };
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
