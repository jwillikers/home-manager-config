{
  config,
  ...
}:
{
  # Make swayidle ineffective, since hypridle is used in its place.
  home.file = {
    "${config.xdg.configHome}/swayidle/config".text = ''
      timeout 9999999 'echo "pseudo timeout"'
    '';
    # "${config.xdg.configHome}/swayidle/config".text = ''
    #   timeout ${toString timeout1} '${lib.getExe pkgs.swaylock} -f'
    #   timeout ${toString timeout2} '${lib.getBin pkgs.hyprland}/bin/hyprctl dispatch dpms off' resume '${lib.getBin pkgs.hyprland}/bin/hyprctl dispatch dpms on'
    #   before-sleep '${lib.getExe pkgs.swaylock} -f'
    #   timeout ${toString timeout3} '${lib.getBin pkgs.systemdMinimal}/bin/systemctl suspend'
    #   lock '${lib.getExe pkgs.swaylock} -f'
    #   unlock '${lib.getExe pkgs.killall} --user "$USER" swaylock'
    # '';
  };
  # services.swayidle = {
  #   enable = true;
  #   events = [
  #     { event = "before-sleep"; command = "${lib.getExe pkgs.swaylock} -f"; }
  #     { event = "lock"; command = "${lib.getExe pkgs.swaylock} -f"; }
  #     { event = "unlock"; command = "${lib.getExe pkgs.killall} --user \"$USER\" swaylock"; }
  #   ];
  #   timeouts = [
  #     { timeout = timeout1; command = "${lib.getExe pkgs.swaylock} -f"; }
  #     { timeout = timeout2; command = "${lib.getBin pkgs.hyprland}/bin/hyprctl dispatch dpms off"; resumeCommand = "${lib.getBin pkgs.hyprland}/bin/hyprctl dispatch dpms on"; }
  #     { timeout = timeout3; command = "${lib.getBin pkgs.systemdMinimal}/bin/systemctl suspend"; }
  #   ];
  # };
}
