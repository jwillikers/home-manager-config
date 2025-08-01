{
  lib,
  pkgs,
  ...
}:
# let
#   installOn = [
#     "precision5350"
#     "x1-yoga"
#   ];
# in
# lib.mkIf (lib.elem hostname installOn) {
{
  systemd.user = {
    services = {
      "ludusavi" = {
        Unit = {
          Description = "Back up game save data with Ludusavi";
          After = [
            # "graphical-session.target"
            "nss-lookup.target"
          ];
          # Requires = [ "graphical-session.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.ludusavi} backup --force";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
        };
      };
    };
    timers = {
      "ludusavi" = {
        Unit = {
          Description = "Back up game save data with Ludusavi regularly";
        };

        Timer = {
          OnCalendar = "hourly";
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
