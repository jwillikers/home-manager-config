{
  config,
  hostname,
  lib,
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
    packages = with pkgs; [
      (config.lib.nixGL.wrap bottles)
    ];
  };
}
