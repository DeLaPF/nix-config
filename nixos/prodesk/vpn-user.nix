{ config, pkgs, lib, ... }:
let
  uName = "vpnuser";
  gName = "vpnuser";
  uHome = "/var/lib/${uName}";
in
{
  imports = [];

  options = {
    vpnUser.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.vpnUser.enable {
    users.users.${uName} = {
      isSystemUser = true;
      description = "VPN User";
      group = gName;
      extraGroups = [ "vpnonly" ];

      home = uHome;
      createHome = true;
      linger = true;

      subUidRanges = [{ startUid = 200000; count = 65536; }];
      subGidRanges = [{ startGid = 200000; count = 65536; }];

      shell = pkgs.zsh;
      packages = [];
    };
    users.groups.${gName} = {};
  };
}
