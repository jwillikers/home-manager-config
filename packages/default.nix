{
  pkgs,
  ...
}:
{
  foot-config = pkgs.callPackage ./foot-config/package.nix { };
  ludusavi-config = pkgs.callPackage ./ludusavi-config/package.nix { };
  ludusavi-steam-deck-config = pkgs.callPackage ./ludusavi-steam-deck-config/package.nix { };
  lutris-config = pkgs.callPackage ./lutris-config/package.nix { };
  openssh-client-config = pkgs.callPackage ./openssh-client-config/package.nix { };
  stretchly-config = pkgs.callPackage ./stretchly-config/package.nix { };
  stretchly-steam-deck-config = pkgs.callPackage ./stretchly-steam-deck-config/package.nix { };
  sublime-merge-config = pkgs.callPackage ./sublime-merge-config/package.nix { };
  sway-config = pkgs.callPackage ./sway-config/package.nix { };
  tio-config = pkgs.callPackage ./tio-config/package.nix { };
  udev-rules = pkgs.callPackage ./udev-rules/package.nix { };
  vim-config = pkgs.callPackage ./vim-config/package.nix { };
}
