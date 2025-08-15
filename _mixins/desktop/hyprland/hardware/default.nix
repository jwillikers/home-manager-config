{
  hostname,
  lib,
  ...
}:
{
  imports = lib.optionals (builtins.pathExists (./. + "/${hostname}")) [ ./${hostname} ];
}
