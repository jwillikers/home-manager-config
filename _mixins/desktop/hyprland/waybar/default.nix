{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.waybar = {
    enable = false;
    # enable = true;
    package = config.lib.nixGL.wrap pkgs.waybar;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        # output = [
        #   "eDP-1"
        # ];
        modules-left = [
          "sway/workspaces"
          "sway/mode"
          "wlr/taskbar"
        ];
        modules-center = [
          "sway/window"
          "custom/hello-from-waybar"
        ];
        modules-right = [
          "mpd"
          "custom/mymodule#with-css-id"
          "temperature"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
        "custom/hello-from-waybar" = {
          format = "hello {}";
          max-length = 40;
          interval = "once";
          exec = pkgs.writeShellScript "hello-from-waybar" ''
            echo "from within waybar"
          '';
        };
      };
    };
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };
}
