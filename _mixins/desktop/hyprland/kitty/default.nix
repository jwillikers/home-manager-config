{
  config,
  pkgs,
  ...
}:
{
  home.packages = [
    config.programs.kitty.package
  ];
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    themeFile = "Solarized_Dark";
  };
}
