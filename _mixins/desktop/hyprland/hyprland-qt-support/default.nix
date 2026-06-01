{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    hyprland-qt-support
  ];
  wayland.windowManager.hyprland.settings.env = [
    {
      _args = [
        "QT_QUICK_CONTROLS_STYLE"
        "org.hyprland.style"
      ];
    }
  ];
}
