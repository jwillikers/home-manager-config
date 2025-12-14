{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
# To get it to work as a compatibility tool in Steam, I had to install through ProtonUp-Qt for some reason.
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
      "${config.xdg.configHome}/steamtinkerlaunch/default_template_source.conf" = {
        source = ./default_template.conf;
        onChange = ''cat ${config.xdg.configHome}/steamtinkerlaunch/default_template_source.conf > ${config.xdg.configHome}/steamtinkerlaunch/default_template.conf'';
      };
      "${config.xdg.configHome}/steamtinkerlaunch/gamecfgs/id/1158850_source.conf" = {
        source = ./gamecfgs/id/1158850.conf;
        onChange = ''cat ${config.xdg.configHome}/steamtinkerlaunch/gamecfgs/id/1158850_source.conf > ${config.xdg.configHome}/steamtinkerlaunch/gamecfgs/id/1158850.conf'';
      };
    };
    packages = with pkgs; [
      steamtinkerlaunch
    ];
  };
}
