{
  config,
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.kitty;
    themeFile = "Solarized_Dark";
  };
}
