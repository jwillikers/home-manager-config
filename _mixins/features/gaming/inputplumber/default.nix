{
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
# Currently, the InputPlumber service must run as root.
# Luckily, it's already installed on the Steam Deck in SteamOS!
# Run:
# sudo systemctl enable inputplumber-suspend
lib.mkIf (lib.elem hostname installOn) {
  home.packages = with pkgs; [
    inputplumber
  ];
}
