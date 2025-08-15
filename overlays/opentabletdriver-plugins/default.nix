{ pkgs, ... }:
{
  "Preset.Binding" = pkgs.callPackage ./Preset.Binding/package.nix { };
}
