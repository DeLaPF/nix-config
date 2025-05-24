# NOTE: requires running with --impure
{ config, lib, ... }:
{
  options = {
    fileAssertions = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          path = lib.mkOption { type = lib.types.str; };
          message = lib.mkOption { type = lib.types.str; default = ""; };
          fatal = lib.mkOption { type = lib.types.bool; default = true; };
        };
      });
      default = [];
    };
  };

  config =
  let
    msg_or_def = (m: p: if m != "" then m else "Missing required file: ${p}");
  in
  {
    assertions = map
      (e: { assertion = builtins.pathExists e.path; message = msg_or_def e.message e.path; })
      (lib.filter (check: check.fatal) config.fileAssertions)
    ;

    warnings = map
      (e: msg_or_def e.message e.path)
      (lib.filter (check: !check.fatal && !(builtins.pathExists check.path)) config.fileAssertions)
    ;
  };
}
