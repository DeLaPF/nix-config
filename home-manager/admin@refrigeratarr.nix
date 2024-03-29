{
  inputs,
  config,
  pkgs,
  hyprland,
  nix-colors,
  ...
}:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
{
  imports = [
    hyprland.homeManagerModules.default
    nix-colors.homeManagerModule

    ./apps/hyprland.nix
    ./dev-envs/main.nix
  ];

  dev-envs = {
    enable = true;
    esp32.enable = true;
    android.enable = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "admin";
    homeDirectory = "/home/admin";
    file.".zsh/plugins/zsh-syntax-highlighting" = {
      source = pkgs.fetchgit {
        url = "https://github.com/zsh-users/zsh-syntax-highlighting.git";
        hash = "sha256-Vt2yKzMRJ34FBFPKrN+GJBZYmBt5ASArrs1dkZcIQmI";
      };
    };
    file.".tmux/plugins/tpm" = {
      source = pkgs.fetchgit {
        url = "https://github.com/tmux-plugins/tpm.git";
        hash = "sha256-1agBX7r4tEdG3fRvsuXHj+YfhsIj0eLLA1Wl8fP+UbQ";
      };
    };
    file.".add_env".text = ''
      source $HOME/.config/.shellHelpers
    '';
    packages = with pkgs; [
      # Devenv
      cargo
      gcc
      home-manager
      ripgrep
      rustc
      stow
      tmux

      # Apps
      firefox
      qpwgraph
    ];
  };

  programs.gh.enable = true;
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      package = (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; });
      size = 12;
    };
  };
  programs.starship.enable = true;

  # Theming
  colorScheme = nix-colors.colorSchemes.dracula;
  gtk = {
    enable = true;
    theme = {
      name = "${config.colorscheme.slug}";
      package = gtkThemeFromScheme { scheme = config.colorscheme; };
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = "gtk2";
      package = pkgs.qt6Packages.qt6gtk2;
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
