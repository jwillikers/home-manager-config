{
  hostname,
  lib,
  pkgs,
  ...
}:
# Bedtime Process Killer
{
  home = {
    packages = with pkgs; [
      bedtime-pk
    ];
  };
  # Start with the SteamDeck for now.
  systemd.user = lib.mkIf (hostname == "steamdeck") {
    services = {
      "bedtime-pk" = {
        Unit = {
          Description = "Kill certain processes when it is bedtime";
          After = [
            "graphical-session.target"
          ];
          BindsTo = [
            "graphical-session.target"
          ];
          ConditionEnvironment = [
            # "HYPRLAND_INSTANCE_SIGNATURE"
            "XDG_RUNTIME_DIR"
            # "DISPLAY"
            # "WAYLAND_DISPLAY"
          ];
        };

        Service = {
          Type = "notify";
          ExecStart = lib.getExe pkgs.bedtime-pk;
          NotifyAccess = "all";
          Restart = "always";
          Slice = "background.slice";
        };
      };
    };
    timers = {
      "bedtime-pk" = {
        Unit = {
          Description = "Kill certain processes when it is bedtime";
        };
        Timer = {
          # OnCalendar = "hourly";
          # OnCalendar = "*:0/15";
          # Start bed time at 21:15.
          OnCalendar = "*-*-* 21:15:00";
        };
        Install = {
          WantedBy = [
            "timers.target"
          ];
        };
      };
    };
  };
}
