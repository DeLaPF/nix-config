{ config, lib, pkgs, ... }:
let
  formatError = msg: ''echo -e "\033[1;31mERROR:\033[0m ${msg}" >&2'';
  formatWarning = msg: ''echo -e "\033[1;33mWARNING:\033[0m ${msg}" >&2'';

  assert_file = { path_str, msg, fatal }: pkgs.stdenv.mkDerivation {
    name = "assert-${(baseNameOf path_str)}";
    # __noChroot = true;  # Allow host filesystem access
    phases = [ "buildPhase" "installPhase" ];
    buildPhase = ''
      # echo "Sandbox contents:"
      # ls -la /
      # ls -la /etc/wireguard

      if [ ! -e "${path_str}" ]; then
        ${
          (if fatal then formatError else formatWarning)
          (if msg != "" then msg else "Missing file: ${path_str}")
        }
        ${if fatal then "exit 1" else ""}
      fi
    '';
    installPhase = "mkdir -p $out";  # Required output
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

    # nix.extraOptions = ''
    #   extra-sandbox-paths ${toString ((lib.unique (map (f: dirOf f.path_str) config.fileAssertions))
    #     ++ config.extraSandboxPaths)}
    # '';

    nix.settings =
    let
      addPaths = (lib.unique (map (f: dirOf f.path_str) config.fileAssertions))
        ++ config.extraSandboxPaths;
    in
    {
      # trusted-users = [ "@wheel" ];
      # sandbox = "relaxed";
      extra-sandbox-paths = addPaths;
      # extra-sandbox-paths = lib.mkForce addPaths;
      # extra-sandbox-paths = lib.unique (map (f: dirOf f.path_str) config.fileAssertions);
      # extra-sandbox-paths =
      #   let
      #     dirs = map (f: dirOf f.path_str) config.fileAssertions;
      #     uniqueDirs = lib.unique dirs;
      #   in lib.trace "Adding to sandbox: ${toString uniqueDirs}" uniqueDirs;
    };
  };
}
