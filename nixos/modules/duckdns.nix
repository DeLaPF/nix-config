{ config, lib, pkgs, ... }:
let
  ddnsEnvFile = "/etc/duckdns/env";
in
{
  imports = [ ./file-assertions.nix ];

  fileAssertions = [ { path_str = ddnsEnvFile; } ];

  systemd = {
    services.duckdns-update = {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = ddnsEnvFile;
      };
      path = [ pkgs.curl ];
      script = ''
        curl -fsSL "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&verbose=true"
      '';
    };

    timers.duckdns-update = {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "*:0/5";  # Every 5 minutes
    };
  };
}
