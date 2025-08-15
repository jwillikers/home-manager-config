{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    hyprland-qt-support
  ];
  wayland.windowManager.hyprland.settings.env = [
    "QT_QUICK_CONTROLS_STYLE,org.hyprland.style"
  ];
}
