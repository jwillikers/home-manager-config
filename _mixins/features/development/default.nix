{
  hostname,
  lib,
  ...
}:
let
  installOn = [
    "precision"
    "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
}
