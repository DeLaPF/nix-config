# Note: This is a paramterized nixos config (as denoted by `.param` sub-ext),
# as such it can not be included directly in config `imports` list
# instead include like: `(import <path> {<required_args>})` in `imports` list

{
  yamlPath,
  sName,
  uName,
  gName,
  suHome ? "/var/lib/su_home",
  asRoot ? false,
  replacements ? {},
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
  
  wantsReplacment = (builtins.length (builtins.attrNames replacements)) > 0;
  yamlNameNoExt = lib.strings.nameFromURL (toString yamlPath) ".";
  podDef = if wantsReplacment then (pkgs.writeText "${yamlNameNoExt}.yaml" (
    lib.foldl (content: r:
      lib.strings.replaceStrings [r.search] [r.replace] content
    ) (builtins.readFile yamlPath) _replacements
  )) else toString yamlPath;
in
{
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  users = lib.mkIf (!asRoot) {
    users.${uName} = {
      isSystemUser = true;
      group = gName;
      home = uHome;
      createHome = true;
      linger = true;

      # Required to allow podman to map internal ids to host ids
      subUidRanges = [{ startUid = 100000; count = 65536; }];
      subGidRanges = [{ startGid = 100000; count = 65536; }];
    };
    groups.${gName} = {};
  };

  systemd.services.${sName} = {
    enable = true;
    description = "${sName} (podman play kube)";
    after = [ "network-online.target" "podman.service" ];
    requires = [ "network-online.target" "podman.service" ];
    wantedBy = [ "multi-user.target" ];

    path = [ "/run/wrappers" ];
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      User = if asRoot then "root" else uName;
      Group = if asRoot then "root" else gName;
      ExecStart = "${pkgs.podman}/bin/podman play kube --replace --userns=keep-id --log-driver=k8s-file ${podDef}";
      ExecStop = "${pkgs.podman}/bin/podman pod stop ${sName}";
      ExecStopPost = "${pkgs.podman}/bin/podman pod rm ${sName}";
    };
  };
}
