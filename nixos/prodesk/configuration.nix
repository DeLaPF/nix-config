{ config, pkgs, outputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../modules/print-server.nix
    ../modules/file-assertions.nix

    # NOTE: Only update on boot to avoid service conflicts:
    # `sudo nixos-rebuild boot --flake .`
    # Parameterized module import
    # (could be called multiple times for multiple services)
    (import ../modules/podman/service.param.nix {
      yamlPath = outputs.configs + "/minecraft/fabric.template.yaml";
      sName = "fabric-server"; uName = "minecraft"; gName = "minecraft";
      replacements = { HOST_PORT = "25565"; MAX_MEMORY = "8G"; };
    })

    (import ../modules/podman/service.param.nix {
      # Make sure in location others can access (world-x perms for all parent dirs)
      # and read (world-r perm for for file)
      yamlPath = "/var/lib/shared/rip.yaml";
      sName = "rip-pod"; uName = "rip"; gName = "rip";
    })
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "wireguard" ];

  # Networking
  networking.hostName = "prodesk"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    25565  # MC Server
  ];
  # services.openssh.enable = true;

  # NOTE: all new paths need to be added and built with fatal = false first
  # otherwise a weird issue with extra-sandbox-paths doesn't allow the files to be seen
  fileAssertions = [
    { path_str = "/etc/wireguard/wg0.conf"; }
  ];
  # NOTE: if using symlinks add symlinked dir as extra path
  # it sometimes works without, but is super spotty
  extraSandboxPaths = [ "/etc/nixos/sysconf" ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.admin = {
    isNormalUser = true;
    description = "admin";
    extraGroups = [ "networkmanager" "wheel" "lpadmin" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # TODO: this may be better to have in an optional module because hardware
  # Enable intel QSV for hardware transcoding
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      intel-media-sdk # QSV up to 11th gen
    ];
  };

  # Jellyfin
  services.jellyfin = {
    enable = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    home-manager
    stow
    wireguard-tools

    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  programs = {
    git.enable = true;
    neovim.enable = true;
    zsh.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
