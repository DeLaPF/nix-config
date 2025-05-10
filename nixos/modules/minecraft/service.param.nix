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
    HOST_PORT = "25565";
    MEMORY = "4G";
  },
}:
{ config, lib, pkgs, ... }:
let
  # TODO: is there a safer method to join paths?
  uHome = "${suHome}/${uName}";
  sDir = "${uHome}/${sName}";

  # Add default `HOST_DIR` if missing, ignored if not in yaml file
  replwHostDir = replacements // { HOST_DIR = replacements.HOST_DIR or sDir; };
  _replacements = lib.mapAttrsToList (name: value: {
    search = "\"{{${name}}}\"";
    replace = value;
  }) replwHostDir;
  
  yamlNameNoExt = lib.strings.nameFromURL (toString yamlPath) ".";
  podDef = pkgs.writeText "${yamlNameNoExt}.yaml" (
    lib.foldl (content: r:
      lib.strings.replaceStrings [r.search] [r.replace] content
    ) (builtins.readFile yamlPath) _replacements
  );
in
{
  # environment.systemPackages = with pkgs; [ shadow ];
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  networking.firewall.allowedTCPPorts = [ hostPort ];
  # boot.kernel.sysctl."kernel.unprivileged_userns_clone" = lib.mkDefault 1;

  users.users.${uName} = {
    isSystemUser = true;
    group = gName;
    home = uHome;
    createHome = true;
    linger = true;
    # packages = with pkgs; [ shadow ];

    # Required to allow podman to map internal ids to host ids
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
  };
  users.groups.${gName} = {};

  systemd.services.${sName} = {
    enable = true;
    description = "${sName} (podman play kube)";
    after = [ "network-online.target" "podman.service" ];
    requires = [ "network-online.target" "podman.service" ];
    wantedBy = [ "multi-user.target" ];

    # path = [ pkgs.shadow ];
    path = [ "/run/wrappers" ];
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      User = uName;
      Group = gName;
      ExecStart = "${pkgs.podman}/bin/podman play kube --replace ${podDef} --userns=keep-id";
      ExecStop = "${pkgs.podman}/bin/podman pod stop ${sName}";
      ExecStopPost = "${pkgs.podman}/bin/podman pod rm ${sName}";
    };
  };
}
