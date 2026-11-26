{
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    "steamdeck"
    # "precision5350"
    # "x1-yoga"
  ];
in
# Keep the Steam Deck awake while using a controller in Desktop Mode.
# KDE doesn't count gamepad input as activity, so the screen could dim or lock while playing with a controller.
# Native games using SDL keep the screen on themselves, but Proton games and Steam's Big Picture mode might not.
# This originally kept Stretchly's natural breaks from treating gamepad play as idle time.
# Natural breaks are now disabled, and input-idle-monitor tracks idle time for Stretchly instead, so this no longer affects it.
# todo Check whether Proton games and Steam keep the screen on themselves.
# stretchly-inhibit logs every request to keep the screen on, including those from games.
# If they do, this is only needed when using a controller outside of games.
lib.mkIf (lib.elem hostname installOn) {
  home.packages = [
    pkgs.joystickwake # Utility to keep the system awake while using a controller
  ];

  systemd.user = {
    services = {
      "joystickwake" = {
        Unit = {
          Description = "Keep the system awake while using a controller";
        };

        Service = {
          Type = "exec";
          ExecStart = "${lib.getExe pkgs.joystickwake}";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
          Slice = "background.slice";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
