{
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    # Prefer the Heroic Flatpak for now.
    # "precision5350"
    # "steamdeck"
    # "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home.packages = with pkgs; [
    heroic
  ];
}
