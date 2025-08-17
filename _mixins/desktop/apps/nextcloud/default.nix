{
  desktop,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    "precision5350"
    "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  systemd.user = {
    services = {
      "com.nextcloud.desktopclient.nextcloud" = {
        Unit = {
          Description = "Run the Nextcloud Desktop Client";
          After = [
            "graphical-session.target"
            "nss-lookup.target"
          ]
          ++ lib.optionals (desktop == "hyprland") [
            "waybar.service"
          ];
          BindsTo = [ "graphical-session.target" ];
          Wants = lib.optionals (desktop == "hyprland") [ "waybar.service" ];
          # Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "exec";
          ExecStart = "${pkgs.flatpak}/bin/flatpak run com.nextcloud.desktopclient.nextcloud --background";
          ExecStop = "${pkgs.flatpak}/bin/flatpak kill com.nextcloud.desktopclient.nextcloud";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
        };

        Install = {
          WantedBy = [ "xdg-desktop-autostart.target" ];
        };
      };
    };
  };
}
