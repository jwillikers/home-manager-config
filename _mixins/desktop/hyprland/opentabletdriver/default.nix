{
  config,
  lib,
  pkgs,
  ...
}:
# Driver for drawing tablets.
# I use a drawing tablet as a mouse to relieve RSI.
# For it to work as a mouse, it needs to be in either relative or absolute mode, not artist mode.
#
# I use the plugin Preset Binding to allow switching between Artist and Absolute modes using the tablets dedicated buttons.
# todo Create a Nix package to install the plugin from a Zip.
# https://github.com/Mrcubix/Preset.Binding
# let
#   # todo Should make a proper module.
#   plugins = [pkgs.opentabletdriver-plugins."Preset.Binding"];
# in
{
  home = {
    #   activation = {
    #     installOpenTabletDriverPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ]
    #       (''
    #         set -eou pipefail
    #       '' + (lib.lists.foldr (plugin: accumulator: ''
    #         # parse plugin version from existing metadata version
    #         for p in ${plugin}/lib/OpenTabletDriver/Plugins/*.zip; do
    #           ${lib.getExe pkgs.unzip} -u "$p" -d ${config.xdg.configHome}/OpenTabletDriver/Plugins
    #         done
    #       '' + accumulator) "" plugins)
    #       );
    # };

    file = {
      "${config.xdg.configHome}/OpenTabletDriver/Presets/mouse.json".source = ./config/Presets/mouse.json;
      "${config.xdg.configHome}/OpenTabletDriver/Presets/artist.json".source =
        ./config/Presets/artist.json;
      # Copy the file to make it writeable.
      "${config.xdg.configHome}/OpenTabletDriver/settings_source.json" = {
        source = ./config/settings.json;
        onChange = ''cat ${config.xdg.configHome}/OpenTabletDriver/settings_source.json > ${config.xdg.configHome}/OpenTabletDriver/settings.json'';
      };
    };

    packages = with pkgs; [
      opentabletdriver
    ];
  };
  # https://github.com/OpenTabletDriver/OpenTabletDriver/blob/master/eng/linux/Generic/usr/lib/systemd/user/opentabletdriver.service
  systemd.user = {
    services = {
      "opentabletdriver" = {
        Unit = {
          Description = "OpenTabletDriver Daemon";
          After = [ config.wayland.systemd.target ];
          PartOf = [
            config.wayland.systemd.target
          ];
          ConditionEnvironment = [
            "|WAYLAND_DISPLAY"
            "|DISPLAY"
          ];
        };

        Service = {
          ExecStart = "${lib.getBin pkgs.opentabletdriver}/bin/otd-daemon";
          Restart = "always";
          RestartSec = 3;
        };

        Install = {
          WantedBy = [ config.wayland.systemd.target ];
        };
      };
    };
  };
}
