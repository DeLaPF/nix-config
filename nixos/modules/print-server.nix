{ config, pkgs, ... }:
{
  # NOTE: users must be in lpadmin group to manage printers

  networking.firewall = {
    allowedTCPPorts = [ 631 ];  # CUPS
    allowedUDPPorts = [ 5353 ];  # Avahi
  };

  # Enable printing services
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      # hplip
      hplipWithPlugin
      gutenprint
      cups-bjnp
      cups-filters
    ];
    browsing = true;
    defaultShared = true;
    # allowFrom = ["localhost" "192.168.1.0/24"];
    allowFrom = ["all"];
    listenAddresses = ["*:631"];
  };

  # Enable Avahi for printer discovery (Bonjour/Zeroconf)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  # Optional: Enable SANE for scanner functionality
  # hardware.sane = {
  #   enable = true;
  #   extraBackends = [ pkgs.hplipWithPlugin ];
  # };
}
