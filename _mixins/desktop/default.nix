{
  desktop,
  lib,
  ...
}:
{
  imports = [ ./apps ] ++ lib.optionals (builtins.pathExists (./. + "/${desktop}")) [ ./${desktop} ];
}
