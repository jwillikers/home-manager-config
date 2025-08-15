{
  config,
  pkgs,
  ...
}:
{
  services.hyprpolkitagent = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.hyprpolkitagent;
  };
}
