{
  config,
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
    (config.lib.nixGL.wrap steam)
  ];

  wayland.windowManager.hyprland.settings.windowrule =
    let
      steamGame = "class:steam_app_[0-9]*";
      steamBigPicture = "title:Steam Big Picture Mode";
      wineTray = "class:explorer.exe";
    in
    [
      "immediate, ${steamGame}"
      "idleinhibit focus, ${steamGame}"
      # todo Move wine to its own file.
      "workspace special silent, ${wineTray}"
      "fullscreen, ${steamBigPicture}"
    ];
}
