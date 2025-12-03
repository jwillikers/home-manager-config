{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    # Disabled due to SteamUI issues.
    # "steamdeck"
    # "precision5350"
    # "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home.packages = [
    (config.lib.nixGL.wrap pkgs.steamback) # Steam game save snapshotting tool
  ];

  # todo
  # Crashes when run in daemon mode.
  # See https://github.com/geeksville/steamback/issues/58
  # systemd.user = {
  #   services = {
  #     "steamback" = {
  #       Unit = {
  #         Description = "Snapshot saves of Steam games";
  #       };

  #       Service = {
  #         Type = "exec";
  #         ExecStart = "${lib.getExe pkgs.steamback} --daemon";
  #         Restart = "on-failure";
  #         RestartSec = 5;
  #         NoNewPrivileges = true;
  #         RestrictRealtime = true;
  #       };

  #       Install = {
  #         WantedBy = [ "graphical-session.target" ];
  #       };
  #     };
  #   };
  # };
}
