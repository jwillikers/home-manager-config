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
# This is used to inhibit idle when playing games on Steam.
# My break timer, Stretchly, incorrectly detects the system as idle on the Steam Deck when playing games through Steam.
# This might not be necessary in the future, as fixes in KDE and Stretchly for Wayland may make it unnecessary.
# todo Check if this is necessary in the future.
lib.mkIf (lib.elem hostname installOn) {
  home.packages = [
    pkgs.joystickwake # Utility to inhibit idle while playing games
  ];

  systemd.user = {
    services = {
      "joystickwake" = {
        Unit = {
          Description = "Inhibit idle when playing video games";
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
