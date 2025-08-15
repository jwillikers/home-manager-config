{
  config,
  hostname,
  lib,
  packages,
  pkgs,
  ...
}:
let
  installOn = [
    "precision5350"
    "steamdeck"
    "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home = {
    file = {
      # Copy the file to make it writeable.
      "${config.xdg.dataHome}/lutris/system_source.yml" = {
        source = packages.lutris-config + "/etc/lutris/system.yml";
        onChange = ''cat ${config.xdg.dataHome}/lutris/system_source.yml > ${config.xdg.dataHome}/lutris/system.yml'';
      };
    };
    packages = with pkgs; [
      (config.lib.nixGL.wrap lutris) # Game launcher
    ];
  };
}
