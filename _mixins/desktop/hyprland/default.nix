{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
# todo tumbler service that runs on Wayblue.
# todo snapshotting tool.
let
  monitors = (import ./monitors.nix { }).${hostname};
in
{
  home = {
    packages = with pkgs; [
      (config.lib.nixGL.wrap kdePackages.dolphin)
      (config.lib.nixGL.wrap hyprpicker)
      (config.lib.nixGL.wrap hyprsysteminfo)
      # grim
      # slurp
    ];
    pointerCursor = {
      hyprcursor.enable = true;
      # todo Pick out a nicer cursor.
      # name = "dark/default";
      # package = pkgs.phinger-cursors;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 32;
      gtk.enable = true;
      x11.enable = true;
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
  imports = [
    ./clipse
    ./dunst
    ./hardware
    ./hypridle
    ./hyprland-config
    # ./hyprlock
    ./swaylock
    ./hyprpaper
    ./kitty
    ./opentabletdriver
    ./swayidle
    # ./tumbler
    ./waybar
    ./wofi
  ];
  services = {
    gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-gnome3;
  };

  systemd.user = {
    sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # gcr
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";

      # Optional, hint Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";
    };
  };

  wayland = {
    systemd.target = "hyprland-session.target";
    windowManager.hyprland = {
      enable = true;
      settings = {
        inherit (monitors) monitor workspace;

        # Workaround issues with the Hyprland Home Manager module not setting systemd.user.sessionVariables
        env = [
          "_JAVA_AWT_WM_NONREPARENTING,1"
          # gcr
          "SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/gcr/ssh"
          # Hint for Electron apps to use Wayland:
          "NIXOS_OZONE_WL,1"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          # --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandLinuxDrmSyncobj
        ];

        cursor = {
          default_monitor = builtins.elemAt (lib.strings.splitString "," (builtins.elemAt config.wayland.windowManager.hyprland.settings.monitor 0)) 0;
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
          };
          touchpad = {
            tap-to-click = true;
          };
        };
        misc = {
          vrr = 3;
        };
        render = {
          direct_scanout = 2;
          # new_render_scheduling = true;
        };
        exec-once = [
          (lib.getExe pkgs.sway-audio-idle-inhibit)
        ];
        exec = [
          "${lib.getBin pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
        ];

        windowrule =
          let
            # todo lutris game
            stretchlyBreak = "class:Stretchly, title:Time to take a break!";
            steamGame = "class:steam_app_[0-9]*";
            kdeconnect-pointer = "class:org.kdeconnect.daemon";
            wineTray = "class:explorer.exe";
            steamBigPicture = "title:Steam Big Picture Mode";
            firefoxPictureInPicture = "class:firefox, title:Picture-in-Picture";
          in
          [
            # todo Use a variable to set the monitor
            "monitor DP-7, ${stretchlyBreak}"
            "float, ${stretchlyBreak}"
            "pin, ${stretchlyBreak}"
            "fullscreen, ${stretchlyBreak}"
            "stayfocused, ${stretchlyBreak}"
            "noclosefor 10000, ${stretchlyBreak}"
            # "noscreenshare, ${stretchlyBreak}"
            # todo idleinhibit
            "immediate, ${steamGame}"
            "idleinhibit focus, ${steamGame}"

            "size 100% 100%, ${kdeconnect-pointer}"
            "float, ${kdeconnect-pointer}"
            "nofocus, ${kdeconnect-pointer}"
            "noblur, ${kdeconnect-pointer}"
            "noanim, ${kdeconnect-pointer}"
            "noshadow, ${kdeconnect-pointer}"
            "noborder, ${kdeconnect-pointer}"
            "plugin:hyprbars:nobar, ${kdeconnect-pointer}"
            "suppressevent fullscreen, ${kdeconnect-pointer}"

            "workspace special silent, ${wineTray}"

            "fullscreen, ${steamBigPicture}"

            "float, ${firefoxPictureInPicture}"
            "pin, ${firefoxPictureInPicture}"
          ];
        xwayland = {
          force_zero_scaling = true;
          # use_nearest_neighbor = false;
        };
      };
      # System is Hyprland variant of Wayblue, so the system manages the Hyprland session.
      # todo copy from wimpy
      systemd = {
        # enable = true;
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
