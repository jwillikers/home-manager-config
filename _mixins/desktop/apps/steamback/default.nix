{
  config,
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
  home.packages = [
    (config.lib.nixGL.wrap pkgs.steamback) # Steam game save snapshotting tool
  ];

  systemd.user = {
    services = {
      "steamback" = {
        Unit = {
          Description = "Snapshot saves of Steam games";
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.steamback} --daemon";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
