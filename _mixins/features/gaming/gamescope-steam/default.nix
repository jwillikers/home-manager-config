# Provide a desktop shortcut to launch Steam in Big Picture Mode through gamescope.
#
# This makes it easy to launch Steam from desktop mode on the Steam Deck and have Steam run as if in gaming mode.
# This allows my break timer to work while gaming in Steam Big Picture Mode.
# Be sure to completely exit Steam before running this shortcut, otherwise nothing will happen.
#
# A script is included to exit Steam from Big Picture Mode.
# The script is installed to ~/.config/gamescope-steam/exit-steam-big-picture-mode.sh.
# Right-click this script and select "Add to Steam" to add it as a shortcut in Steam.
# Run the shortcut from within Steam to exit Big Picture Mode.
{
  config,
  hostname,
  lib,
  ...
}:
let
  installOn = [
    # "precision5350"
    "steamdeck"
    # "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home = {
    file = {
      "${config.xdg.dataHome}/applications/steam-big-picture-mode.desktop".source =
        ./steam-big-picture-mode.desktop;
      # Right-click this script and select "Add to Steam" to add it as a shortcut in Steam.
      # The script is installed to ~/.config/gamescope-steam/exit-steam-big-picture-mode.sh.
      "${config.xdg.configHome}/gamescope-steam/exit-steam-big-picture-mode_source.sh" = {
        source = ./exit-steam-big-picture-mode.sh;
        onChange = ''
          cat ${config.xdg.configHome}/gamescope-steam/exit-steam-big-picture-mode_source.sh > ${config.xdg.configHome}/gamescope-steam/exit-steam-big-picture-mode.sh
          chmod +x ${config.xdg.configHome}/gamescope-steam/exit-steam-big-picture-mode.sh
        '';
        executable = true;
      };
    };
  };
}
