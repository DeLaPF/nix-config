{ config, pkgs, lib, ... }:
{
  imports = [];

  options = {
    vpnUser.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.vpnUser.enable {
    users.users.vpnuser = {
      isSystemUser = true;
      description = "VPN User";
      shell = pkgs.zsh;
      packages = [];
    };
  };
}
