{ config, lib, pkgs, ... }:
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
  cfg = config.minecraft;

  # TODO: improve replacement with foldl' and replacement paring (possibly validate)
  podDef = pkgs.writeText "minecraft-replaced.yaml" (
    lib.strings.replaceStrings [
      "&${yamlDefaults.hostDir.name} ${yamlDefaults.hostDir.val}"
      "&${yamlDefaults.hostPort.name} ${toString yamlDefaults.hostPort.val}"
    ] [
      "&${yamlDefaults.hostDir.name} ${cfg.hostDir}"
      "&${yamlDefaults.hostPort.name} ${toString cfg.hostPort}"
    ] (builtins.readFile ./minecraft.yaml)
  );
in
{
  options.minecraft = {
    enable = lib.mkEnableOption "Enable minecraft service";
    hostDir = lib.mkOption {
      type = lib.types.str;
      default = yamlDefaults.hostDir.val;
      description = "Host machine abs path";
    };
    hostPort = lib.mkOption {
      type = lib.types.port;
      default = yamlDefaults.hostPort.val;
      description = "Host port to run the service under";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "minecraft-server";
      description = "Name of the service";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "minecraft";
      description = "User to run the service under";
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "minecraft";
      description = "Group to run the service under";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    networking.firewall.allowedTCPPorts = [ cfg.hostPort ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.hostDir;
      createHome = true;
      linger = true;

      # Required to allow podman to map internal ids to host ids
      subUidRanges = [{ startUid = 100000; count = 65536; }];
      subGidRanges = [{ startGid = 100000; count = 65536; }];
    };
    users.groups.${cfg.group} = {};

    # Let the user own the data directory
    systemd.tmpfiles.rules = [
      "d ${cfg.hostDir} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.${cfg.name} = {
      description = "Run podman ${cfg.name}";
      after = [ "network.target" "podman.service" ];
      requires = [ "podman.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = cfg.hostDir;
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.podman}/bin/podman play kube --replace ${podDef}";
        ExecStop = "${pkgs.podman}/bin/podman pod stop ${cfg.name}";
        ExecStopPost = "${pkgs.podman}/bin/podman pod rm ${cfg.name}";
      };
    };
  };
}
