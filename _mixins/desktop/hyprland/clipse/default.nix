{
  lib,
  pkgs,
  ...
}:
{
  services.clipse = {
    enable = true;
    systemdTarget = "hyprland-session.target";
  };
  wayland.windowManager.hyprland.settings = {
    # exec-once = [
    #   "${lib.getExe pkgs.clipse} -listen"
    # ];
    windowrule = [
      "float, class:(clipse)" # ensure you have a floating window class set if you want this behavior
      "size 622 652, class:(clipse)" # set the size of the window as necessary
    ];
    bind = [
      # "SUPER, V, exec, kitty --class clipse -e 'clipse'"
      "$mainMod, I, exec, ${lib.getExe pkgs.kitty} --class clipse -e 'clipse'"
    ];
  };
}
