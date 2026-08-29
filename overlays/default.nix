{
  inputs,
}:
{
  efficient-compression-tool = _final: prev: {
    efficient-compression-tool = prev.efficient-compression-tool.overrideAttrs (_prevAttrs: {
      patches = [
        # from https://github.com/fhanau/Efficient-Compression-Tool/issues/145
        ./ect-gcc-15-O3-fix.patch
      ];
    });
  };
  with_pngout = _final: prev: {
    image_optim = prev.image_optim.override { withPngout = true; };
    pdfsizeopt = prev.pdfsizeopt.override { withPngout = true; };
    minuimus = prev.minuimus.override { withPngout = true; };
  };
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
  # Update to the latest version of Stretchly.
  # https://github.com/NixOS/nixpkgs/pull/474659
  stretchly = _final: prev: {
    stretchly = prev.stretchly.overrideAttrs (_prevAttrs: rec {
      version = "1.22.1";
      src = prev.fetchurl {
        url = "https://github.com/hovancik/stretchly/releases/download/v${version}/stretchly-${version}.tar.xz";
        hash = "sha256-Q5Z6os50E5D5aqBK/k5GBlgo3i1HmpOl3atrhvvPGnI=";
      };
    });
  };
  packages = _final: prev: {
    # opentabletdriver-plugins = prev.lib.recurseIntoAttrs (prev.callPackage ./opentabletdriver-plugins { });
    bedtime-pk = prev.callPackage ./bedtime-pk/package.nix { };
    stretchly-hyprland = prev.callPackage ./stretchly-hyprland/package.nix { };
    stretchly-inhibit = prev.callPackage ./stretchly-inhibit/package.nix { };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstablePackages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
      # overlays = [
      #   # Apply the same rofi-unwrapped modification to unstable packages
      #   (_final: _prev: {
      #     rofi-unwrapped = _prev.rofi-unwrapped.overrideAttrs (oldAttrs: {
      #       postInstall = (oldAttrs.postInstall or "") + ''
      #         rm -f $out/share/applications/rofi.desktop
      #         rm -f $out/share/applications/rofi-theme-selector.desktop
      #       '';
      #     });
      #   })
      # ];
    };
  };
}
