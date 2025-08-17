{
  config,
  lib,
  pkgs,
  ...
}:
let
  monitor = builtins.elemAt (builtins.elemAt config.wayland.windowManager.hyprland.settings.monitor 0)
    .output;
in
{
  programs.hyprlock = {
    enable = true;
    # Mixing /etc/pam.d/login from Fedora with PAM modules from Nix breaks things.
    # PAM unable to dlopen(/nix/store/.../lib/security/pam_fprintd.so)
    # Hyprlock must be installed from source
    package = pkgs.runCommandLocal "empty" { } "mkdir $out";
    settings = {
      general = {
        grace = 5;
        hide_cursor = true;
        immediate_render = true;
      };
      animations = {
        enabled = true;
        bezier = [
          "easeout,0.5, 1, 0.9, 1"
          "easeoutback,0.34,1.22,0.65,1"
        ];
        animation = [
          "fade, 1, 3, easeout"
          "inputField, 1, 1, easeoutback"
        ];
      };
      background = {
        path = "/usr/share/backgrounds/default-dark.jxl";
        blur_passes = 4;
      };
      input-field = {
        inherit monitor;
        #   font_color = "rgb(${lib.removePrefix "#" config.colorscheme.colors.on_surface})";
        # font_family = config.fontProfiles.regular.name;

        position = "0, 20%";
        halign = "center";
        valign = "bottom";

        # Hide outline and filling
        outline_thickness = 0;
        inner_color = "rgba(00000000)";
        check_color = "rgba(00000000)";
        fail_color = "rgba(00000000)";
      };
      label = {
        inherit monitor;
        text = "$TIME";
        # color = "rgb(${lib.removePrefix "#" config.colorscheme.colors.on_surface})";
        # font_family = config.fontProfiles.regular.name;
        font_size = "180";

        position = "0, 0";
        halign = "center";
        valign = "center";
      };
    };
  };

  wayland.windowManager.hyprland = {
    settings = {
      bind =
        let
          hyprlock = lib.getExe config.programs.hyprlock.package;
        in
        [
          # L?
          "SUPER,backspace,exec,${hyprlock} --immediate"
          # "SUPER,XF86Calculator,exec,${hyprlock} --immediate"
        ];
    };
  };
}
