{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    config.programs.wofi.package
  ];
  programs.wofi = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.wofi;
  };
}
