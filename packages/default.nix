{
  pkgs,
  ...
}:
{
  foot-config = pkgs.callPackage ./foot-config/package.nix { };
  openssh-client-config = pkgs.callPackage ./openssh-client-config/package.nix { };
  stretchly-config = pkgs.callPackage ./stretchly-config/package.nix { };
  sublime-merge-config = pkgs.callPackage ./sublime-merge-config/package.nix { };
  sway-config = pkgs.callPackage ./sway-config/package.nix { };
  tio-config = pkgs.callPackage ./tio-config/package.nix { };
  udev-rules = pkgs.callPackage ./udev-rules/package.nix { };
  vim-config = pkgs.callPackage ./vim-config/package.nix { };
}
