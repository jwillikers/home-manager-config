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
    window_rule = [
      {
        match = {
          class = "^(clipse)$";
        };
        float = true;
        # size = "{\"monitor_w\", \"monitor_h\"}";
        size = "{\"monitor_w*0.6\", \"monitor_h*0.6\"}";
        # size = "{622, 652}";
      }
    ];
    # "float, class:(clipse)" # ensure you have a floating window class set if you want this behavior
    # "size 622 652, class:(clipse)" # set the size of the window as necessary
    bind = [
      {
        _args = [
          "SUPER + I"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${lib.getExe pkgs.kitty} --class clipse -e clipse\")")
        ];
      }
    ];
  };
}
