{
  inputs,
  lib,
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

    ./dev-envs/main.nix
  ];

  dev-envs = {
    enable = true;
    esp32.enable = true;
    android.enable = true;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "admin";
    homeDirectory = "/home/admin";
    packages = with pkgs; [];
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
  };

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

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ "eDP-1,1920x1080@59,0x0,1" ];
      env = [ "XCURSOR_SIZE,24" ];
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
            natural_scroll = "no";
        };
      
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };
      exec-once = [ "kitty" ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(8e0db5ff)";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        allow_tearing = "false";
      };
      decoration = {
        rounding = 10;
        blur = {
            enabled = "true";
            size = 3;
            passes = 1;
        };
        drop_shadow = "yes";
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };
      animations = {
        # TODO: Determine if I should disable
        enabled = "yes";
      
        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = "yes"; # you probably want this
      };
      master = {
        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_is_master = "false";
      };
      gestures = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more
          workspace_swipe = "off";
      };
      # Example windowrule v1
      # windowrule = float, ^(kitty)$
      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    };
    extraConfig = ''
      # See https://wiki.hyprland.org/Configuring/Keywords/ for more
      $mainMod = SUPER;

      bind = $mainMod, Return, exec, kitty
      bind = $mainMod, Q, killactive,
      bind = $mainMod SHIFT, Q, exit,
      bind = $mainMod, F, fullscreen,
      bind = $mainMod, M, fullscreen, 1
      bind = $mainMod, E, exec, dolphin
      bind = $mainMod, V, togglefloating, 
      bind = $mainMod, R, exec, wofi --show drun
      bind = $mainMod, P, pseudo, # dwindle
      #bind = $mainMod, J, togglesplit, # dwindle
      
      # Brightness & Volume
      binde =, XF86MonBrightnessUp, exec, brightnessctl set 5%+
      binde =, XF86MonBrightnessDown, exec, brightnessctl set 5%-
      binde =, XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+
      binde =, XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      
      # Move focus with mainMod + arrow keys
      bind = $mainMod, H, movefocus, l
      bind = $mainMod, L, movefocus, r
      bind = $mainMod, K, movefocus, u
      bind = $mainMod, J, movefocus, d
      
      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      
      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10
      
      # Example special workspace (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic
      
      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1
      
      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
