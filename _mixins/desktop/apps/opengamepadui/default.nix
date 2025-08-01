{
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    "steamdeck"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home.packages = with pkgs; [ opengamepadui ];
}
