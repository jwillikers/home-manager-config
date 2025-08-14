{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.wofi = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.wofi;
    # settings = {

    # };
  };
}
