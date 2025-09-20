_: {
  gcr = _final: prev: {
    gcr = prev.gcr.overrideAttrs (prevAttrs: {
      mesonFlags = prevAttrs.mesonFlags ++ [ "-Dssh_agent=true" ];
    });
  };
  heroic = _final: prev: {
    heroic = prev.heroic.override {
      extraPkgs = pkgs: [
        pkgs.gamescope
        pkgs.gamemode
      ];
    };
  };
  packages = _final: prev: {
    # opentabletdriver-plugins = prev.recurseIntoAttrs (prev.callPackage ./opentabletdriver-plugins { });
    bedtime-pk = prev.callPackage ./bedtime-pk/package.nix { };
    stretchly-hyprland = prev.callPackage ./stretchly-hyprland/package.nix { };
    stretchly-inhibit = prev.callPackage ./stretchly-inhibit/package.nix { };
  };
}
