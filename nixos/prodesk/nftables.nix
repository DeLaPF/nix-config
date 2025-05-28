{ config, lib, ... }:
{
  options = {
    nftables.extraRules = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
    };
  };

  config =
  let
    vpnonlyGID = 5000;  # arbitrary
    vpnonlyFWMark = lib.fromHexString "0xc8";  # arbitrary, but derived env var must be used in wg config
  in
  {
    environment.sessionVariables = {
      VPNONLY_FW_MARK = vpnonlyFWMark;
    };

    networking = {
      firewall.enable = false;  # disable nixos iptables based firewall
      nftables.enable = true;
      nftables.ruleset =
      let
        nftablesDir = ./nftables;
        rulesFiles = builtins.readDir (nftablesDir + "/rules");
      in
      ''
        # Flush existing ruleset
        flush ruleset

        # Defs
        define vpnonlyGID = ${toString vpnonlyGID}
        define vpnonlyFWMark = ${toString vpnonlyFWMark}

        # Base
        ${lib.fileContents "${nftablesDir}/base.nft"}

        # Rules
        ${lib.concatStringsSep "\n\n" (map
          (f: lib.fileContents "${nftablesDir}/rules/${f}")
          (builtins.attrNames rulesFiles)
        )}

        # Extra (usually conditionally applied)
        ${lib.concatStringsSep "\n\n" (map
          (f: lib.fileContents f)
          config.nftables.extraRules
        )}
      '';
    };

    users.groups.vpnonly = {
      gid = vpnonlyGID;
    };
  };
}
