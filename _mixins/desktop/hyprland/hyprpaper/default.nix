{
  config,
  lib,
  ...
}:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true;
      splash = false;
      preload = [ "/usr/share/backgrounds/default-dark.jxl" ];
      wallpaper = [
        # todo For loop for each monitor.
        "desc:${builtins.elemAt (lib.strings.splitString "," (builtins.elemAt config.wayland.windowManager.hyprland.settings.monitor 0)) 0}, /usr/share/backgrounds/default-dark.jxl"
        # The description doesn't work for the laptop's monitor for some reason...
        "eDP-1, /usr/share/backgrounds/default-dark.jxl"
      ];
    };
  };
}
