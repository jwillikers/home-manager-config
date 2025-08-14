{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  monitors = (import ./monitors.nix { }).${hostname};
in
{
  home = {
    packages = with pkgs; [
      (config.lib.nixGL.wrap kdePackages.dolphin)
      (config.lib.nixGL.wrap hyprsysteminfo)
      config.programs.kitty.package
      # (config.lib.nixGL.wrap swaybg)
      (config.lib.nixGL.wrap wofi)
      (config.lib.nixGL.wrap waybar)
    ];
    pointerCursor = {
      hyprcursor.enable = true;
      name = "dark/default";
      package = pkgs.phinger-cursors;
      size = 32;
      # gtk.enable = true;
      # # x11.enable = true;
      # package = pkgs.bibata-cursors;
      # name = "Bibata-Modern-Classic";
    };
    # Workaround issues with the Home Manager module not setting systemd.user.sessionVariables.
    # Setting them here ensures they are available in the shell.
    sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = 1;
      # gcr
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
      # Hint for Electron apps to use Wayland:
      NIXOS_OZONE_WL = 1;
    };
  };
  # gtk = {
  #   enable = true;
  #   theme = {
  #     package = pkgs.flat-remix-gtk;
  #     name = "Flat-Remix-GTK-Grey-Darkest";
  #   };
  #   iconTheme = {
  #     package = pkgs.adwaita-icon-theme;
  #     name = "Adwaita";
  #   };
  #   font = {
  #     name = "Sans";
  #     size = 11;
  #   };
  # };
  imports = [
    ./clipse
    ./hypridle
    ./hyprland-config
    ./hyprlock
    ./hyprpaper
    ./kitty
    ./opentabletdriver
    ./swayidle
    # ./waybar
  ];
  services = {
    gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-gnome3;
  };

  systemd.user = {
    sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # gcr
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";

      # Optional, hint Electron apps to use Wayland:
      NIXOS_OZONE_WL = "1";
    };
  };

  wayland = {
    systemd.target = "hyprland-session.target";
    windowManager.hyprland = {
      package = config.lib.nixGL.wrap pkgs.hyprland;
      # https://www.reddit.com/r/NixOS/comments/1gkrota/nixos_nvidia_hyprland_vscode_blinking/
      # package = config.lib.nixGL.wrap (pkgs.hyprland.override {
      #   wrapRuntimeDeps = false;
      # });
      # portalPackage = (config.lib.nixGL.wrap pkgs.xdg-desktop-portal-hyprland);
      enable = true;
      settings = {
        # Inherit the default system config.
        # source = "/usr/share/hypr/hyprland.conf";

        inherit (monitors) monitor;

        # Workaround issues with the Hyprland Home Manager module not setting systemd.user.sessionVariables
        env = [
          "_JAVA_AWT_WM_NONREPARENTING,1"
          # gcr
          "SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/gcr/ssh"
          # Hint for Electron apps to use Wayland:
          "NIXOS_OZONE_WL,1"

          # NVIDIA
          # https://wiki.hypr.land/Configuring/Environment-variables/#nvidia-specific
          # "GBM_BACKEND,nvidia-drm"
          # "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          # "LIBVA_DRIVER_NAME,nvidia"
          # "__GL_GSYNC_ALLOWED,1"
          # "__GL_VRR_ALLOWED,0"
        ];

        cursor = {
          default_monitor = monitors.monitor [ 0 ];
        };
        device = {
          name = "9610:30:Pine64_Pinebook_Pro";
          kb_layout = "us";
          kb_variant = "colemak_dh";
          kb_options = "grp:alt_shift_toggle";
        };
        input = {
          tablet = {
            output = [ ];
            # relative_input = true;
          };
          touchpad = {
            tap-to-click = true;
          };
        };
        exec-once = [
          (lib.getExe pkgs.sway-audio-idle-inhibit)
        ];
        exec = [
          "${lib.getBin pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
        ];
      };
      # System is Hyprland variant of Wayblue, so the system manages the Hyprland session.
      # todo copy from wimpy
      # systemd.enable = true;
      systemd = {
        enableXdgAutostart = true;
        variables = [ "--all" ];
      };
      xwayland.enable = true;
    };
  };
  # https://github.com/hyprwm/hyprland-wiki/issues/409
  # https://github.com/nix-community/home-manager/pull/4707
  xdg.portal = {
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
    configPackages = [ config.wayland.windowManager.hyprland.package ];
    # configPackages = [ (config.lib.nixGL.wrap pkgs.hyprland) ];
    # enable = lib.mkForce false;
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gtk
      # https://github.com/Misterio77/nix-config/blob/36f76f9a4e6dd45c692755858a248c26883184f5/home/gabriel/features/desktop/hyprland/default.nix#L40
      (pkgs.xdg-desktop-portal-hyprland.override {
        hyprland = config.wayland.windowManager.hyprland.package;
      })
    ];
    xdgOpenUsePortal = true;
  };
}
