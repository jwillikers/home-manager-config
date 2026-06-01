{
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
  home.packages = with pkgs; [
    # config.programs.lutris.steamPackage
    steam
  ];

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match = {
        class = "^(steam_app_[0-9]+)$";
      };
      immediate = true;
      idle_inhibit = "focus";
    }
    {
      match = {
        class = "^(explorer.exe)$";
      };
      workspace = "special silent";
    }
    {
      match = {
        title = "^(Steam Big Picture Mode)$";
      };
      fullscreen = true;
    }
    # todo Move wine to its own file.
  ];
}
