{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    opentabletdriver
  ];
  # https://github.com/OpenTabletDriver/OpenTabletDriver/blob/master/eng/linux/Generic/usr/lib/systemd/user/opentabletdriver.service
  systemd.user = {
    services = {
      "opentabletdriver" = {
        Unit = {
          Description = "OpenTabletDriver Daemon";
          After = [ "graphical-session.target" ];
          PartOf = [
            "graphical-session.target"
          ];
          ConditionEnvironment = [
            "|WAYLAND_DISPLAY"
            "|DISPLAY"
          ];
        };

        Service = {
          ExecStart = "${lib.getBin pkgs.opentabletdriver}/bin/otd-daemon";
          Restart = "always";
          RestartSec = 3;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
