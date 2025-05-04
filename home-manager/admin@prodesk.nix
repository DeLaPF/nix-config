{
  inputs,
  config,
  pkgs,
  ...
}:
{
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
        hash = "sha256-IIcGYa0pXdll/XDPA15zDBkLUuLhTdrqwS9sn06ce0Y=";
      };
    };
    file.".tmux/plugins/tpm" = {
      source = pkgs.fetchgit {
        url = "https://github.com/tmux-plugins/tpm.git";
        hash = "sha256-1agBX7r4tEdG3fRvsuXHj+YfhsIj0eLLA1Wl8fP+UbQ=";
      };
    };
    packages = with pkgs; [
      # Devenv
      gcc
      home-manager
      ripgrep
      stow
      tmux
    ];
  };

  programs = {
    # TODO: Would be nice to have an alternative,
    # but need to specify extensions dev mode and enable force dark browser
    # brave://extensions brave://flags
    chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }  # uBlock Origin
        { id = "chphlpgkkbolifaimnlloiipkdnihall"; }  # OneTab
        { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; }  # SurfingKeys
        # TODO: determine better method for handling and loading config
        # https://raw.githubusercontent.com/rose-pine/surfingkeys/main/dist/rose-pine.js
        # Once config loaded add below then unset
        # Additional config
        # api.map('H', 'history.back');
        # api.map('L', 'history.forward');
        # api.map('J', 'previousTab');
        # api.map('K', 'nextTab');
        # // api.unmap('S');
        # // api.unmap('D');
        # // api.unmap('E');
        # // api.unmap('R');
      ];
    };
    gh.enable = true;
    git = {
      enable = true;
      userName = "DeLaPF";
      userEmail = "de.alafia@gmail.com";
    };
    ghostty = {
      enable = true;
      # enableZshIntegration = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    starship.enable = true;
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
