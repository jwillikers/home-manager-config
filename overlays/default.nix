_: {
  packages = _final: prev: {
    # opentabletdriver-plugins = prev.recurseIntoAttrs (prev.callPackage ./opentabletdriver-plugins { });
    stretchly-hyprland = prev.callPackage ./stretchly-hyprland/package.nix { };
  };
  gcr = _final: prev: {
    gcr = prev.gcr.overrideAttrs (prevAttrs: {
      mesonFlags = prevAttrs.mesonFlags ++ [ "-Dssh_agent=true" ];
    });
  };
}
