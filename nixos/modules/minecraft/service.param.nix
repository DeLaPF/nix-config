# Note: This is a paramterized nixos config (as denoted by `.param` sub-ext),
# as such it can not be included directly in config `imports` list
# instead include like: `(import <path> {<required_args>})` in `imports` list

{
  # TODO: type check/assert
  yamlPath ? ./minecraft.template.yaml,
  sName ? "minecraft-server",
  uName ? "minecraft",
  gName ? "minecraft",
  suHome ? "/var/lib/su_home",
  hostPort ? 25565,
  replacements ? {
    # It feels like HOST_DIR would be better set by sDir,
    # but that isn't available here
    HOST_DIR = "/var/lib/su_home/minecraft/minecraft-server";
    HOST_PORT = "25565";
    MEMORY = "4G";
  },
}:
{ config, lib, pkgs, ... }:
let
  # TODO: is there a safer method to join paths?
  uHome = "${suHome}/${uName}";
  sDir = "${uHome}/${sName}";

  _replacements = lib.mapAttrsToList (name: value: {
    search = "\"{{${name}}}\"";
    replace = value;
  }) replacements;
  
  yamlNameNoExt = lib.strings.nameFromURL (toString yamlPath) ".";
  podDef = pkgs.writeText "${yamlNameNoExt}.yaml" (
    lib.foldl (content: replacement:
      lib.strings.replaceStrings [replacement.search] [replacement.replace] content
    ) (builtins.readFile yamlPath) _replacements
  );
in
{
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  networking.firewall.allowedTCPPorts = [ hostPort ];

  users.users.${uName} = {
    isSystemUser = true;
    group = gName;
    home = uHome;
    createHome = true;
    linger = true;

    # Required to allow podman to map internal ids to host ids
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
  };
  users.groups.${gName} = {};

  # Let the user own the data directory
  # systemd.tmpfiles.rules = [
  #   # Note: 3 bits <read><write><exec>, 3 3bit values <owner><group><world>
  #   # Example: 777 -> 111,111,111 -> read, write, exec for all
  #   # Example: 750 -> 111,111,111 -> rwe for owner, re for group, nothing for world
  #   # Q: why the leading 0?
  #   "d ${uHome} 0750 ${uName} ${gName} - -"
  # ];

  systemd.services.${sName} = {
    description = "Run podman ${sName}";
    after = [ "network.target" "podman.service" ];
    requires = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      Slice = "user.slice";
      Delegate = true;  # Allow cgroups management
      NotifyAccess = "all";
      User = uName;
      Group = gName;
      ExecStart = "${pkgs.podman}/bin/podman play kube --replace ${podDef}";
      ExecStop = "${pkgs.podman}/bin/podman pod stop ${sName}";
      ExecStopPost = "${pkgs.podman}/bin/podman pod rm ${sName}";
    };
  };
}
