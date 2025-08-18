{
  desktop,
  hostname,
  lib,
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
      "im.riot.Riot" = {
        Unit = {
          Description = "Start the Element Flatpak in the background";
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
          # Can't use Nix's flatpak command with electron apps for reasons.
          ExecStart = "/usr/bin/flatpak run im.riot.Riot --hidden";
          ExecStop = "/usr/bin/flatpak kill im.riot.Riot";
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
