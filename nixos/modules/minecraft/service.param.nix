# Note: This is a paramterized nixos config (as denoted by `.param` sub-ext),
# as such it can not be included directly in config `imports` list
# instead include like: `(import <path> {<required_args>})` in `imports` list

let
  # TODO: add memory control
  yamlDefaults = {
    hostDir = {
      name = "host_dir";
      val = "/var/lib/minecraft-data";
    };
    hostPort = {
      name = "host_port";
      val = 25565;
    };
  };
in {
  # TODO: type check/assert
  yamlPath ? ./minecraft.yaml,
  sName ? "minecraft-server",
  uName ? "minecraft",
  gName ? "minecraft",
  hostDir ? yamlDefaults.hostDir.val,
  hostPort ? yamlDefaults.hostPort.val,
}:
{ config, lib, pkgs, ... }:
let
  # TODO: improve replacement with foldl' and replacement paring (possibly validate)
  podDef = pkgs.writeText "${baseNameOf yamlPath}-replaced.yaml" (
    lib.strings.replaceStrings [
      "&${yamlDefaults.hostDir.name} ${yamlDefaults.hostDir.val}"
      "&${yamlDefaults.hostPort.name} ${toString yamlDefaults.hostPort.val}"
    ] [
      "&${yamlDefaults.hostDir.name} ${hostDir}"
      "&${yamlDefaults.hostPort.name} ${toString hostPort}"
    ] (builtins.readFile yamlPath)
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
    home = hostDir;
    createHome = true;
    linger = true;

    # Required to allow podman to map internal ids to host ids
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
  };
  users.groups.${gName} = {};

  # Let the user own the data directory
  systemd.tmpfiles.rules = [
    # Note: 3 bits <read><write><exec>, 3 3bit values <owner><group><world>
    # Example: 777 -> 111,111,111 -> read, write, exec for all
    # Example: 750 -> 111,111,111 -> rwe for owner, re for group, nothing for world
    # Q: why the leading 0?
    "d ${hostDir} 0750 ${uName} ${gName} - -"
  ];

  systemd.services.${sName} = {
    description = "Run podman ${sName}";
    after = [ "network.target" "podman.service" ];
    requires = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # Type = "oneshot";
      Type = "simple";
      RemainAfterExit = true;
      WorkingDirectory = hostDir;
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
