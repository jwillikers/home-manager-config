{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.hypridle = {
    enable = true;
    settings =
      let
        isLocked = "${lib.getBin pkgs.procps}/bin/pgrep swaylock";
        isDischarging = "${lib.getExe pkgs.gnugrep} Discharging /sys/class/power_supply/BAT{0,1}/status -q";
      in
      {
        general = {
          # lock_cmd = "if ! ${isLocked}; then ${lib.getExe config.programs.swaylock.package}; fi";
          # Due to issues between Nix and system PAM, the system executable of swaylock has to be used.
          # This will probably become hyprlock when it's in Fedora again.
          lock_cmd = "if ! ${isLocked}; then /usr/bin/swaylock; fi";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "${lib.getBin config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on && ${lib.getExe pkgs.stretchly} reset";
          inhibit_sleep = 3; # Wait for lock before suspend
        };
        listener = [
          # Dim screen
          # {
          #   timeout = 10;
          #   on-timeout = "${lib.getExe pkgs.brightnessctl} --save";
          #   on-resume = "${lib.getExe pkgs.brightnessctl} --restore";
          # }
          #
          # Disable keyboard backlight
          # {
          #   timeout = 30;
          #   on-timeout = "${lib.getExe pkgs.brightnessctl} --device *:kbd_backlight --save set 0";
          #   on-resume = "${lib.getExe pkgs.brightnessctl} --device *:kbd_backlight --restore";
          # }

          # Reset Stretchly breaks
          {
            timeout = 900; # 15 minutes
            on-timeout = "${lib.getExe pkgs.stretchly} pause";
            on-resume = "${lib.getExe pkgs.stretchly} reset";
          }
          # Turn off screen
          {
            timeout = 900; # 15 minutes
            on-timeout = "${lib.getBin config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
            on-resume = "${lib.getBin config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
          }
          # Lock screen
          {
            timeout = 3600; # 60 minutes
            on-timeout = "loginctl lock-session";
          }

          # If already locked
          # {
          #   timeout = 15;
          #   on-timeout = "if ${isLocked}; then ${lib.getExe pkgs.brightnessctl} set 75%-; fi";
          # }
          {
            timeout = 40;
            on-timeout = "if ${isLocked}; then ${lib.getBin config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off; ${lib.getExe pkgs.stretchly} pause; fi";
            on-resume = "${lib.getBin config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on && ${lib.getExe pkgs.stretchly} reset";
          }

          # If discharging
          {
            timeout = 901; # 15 minutes
            on-timeout = "if ${isDischarging}; then ${lib.getBin pkgs.systemdMinimal}/bin/systemctl suspend; fi";
          }
        ];
      };
    # systemdTarget = "hyprland-session.target";
  };
  # systemd.user.services."hypridle".Unit.ConditionEnvironment = [
  #   "|WAYLAND_DISPLAY"
  # ];
}
