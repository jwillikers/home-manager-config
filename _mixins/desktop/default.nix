{
  desktop,
  lib,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${desktop}")) ./${desktop};
  # ++ lib.optional (builtins.pathExists (
  #   ./. + "/${desktop}/${username}/default.nix"
  # )) ./${desktop}/${username};
}
