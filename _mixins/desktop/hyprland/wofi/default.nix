{
  config,
  pkgs,
  ...
}:
{
  home.packages = [
    config.programs.wofi.package
  ];
  programs.wofi = {
    enable = true;
    package = pkgs.wofi;
  };
}
