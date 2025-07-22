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
    username = "media";
    homeDirectory = "/home/media";
    packages = with pkgs; [
      home-manager
      moonlight-qt
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
        # Ref: https://github.com/brookhong/Surfingkeys/blob/3d799e10c38631fcf314f3dab0bfff54372e5237/src/content_scripts/common/default.js
        # api.mapkey('H', 'History back', () => history.go(-1));
        # api.mapkey('L', 'History forward', () => history.go(1));
        # api.unmap('S');
        # api.unmap('D');

        # api.mapkey('J', 'Tab Up', () => api.RUNTIME("previousTab"));
        # api.mapkey('K', 'Tab Down', () => api.RUNTIME("nextTab"));
        # api.unmap('E');
        # api.unmap('R');
      ];
    };
    neovim = {
      enable = true;
      defaultEditor = true;
    };
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
