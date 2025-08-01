_: {
  ludusavi-rclone = final: prev: {
    ludusavi = prev.ludusavi.overrideAttrs (_prevAttrs: {
      postFixup =
        let
          libPath = prev.lib.makeLibraryPath (
            with final;
            [
              libGL
              bzip2
              fontconfig
              freetype
              xorg.libX11
              xorg.libXcursor
              xorg.libXrandr
              xorg.libXi
              libxkbcommon_8
              vulkan-loader
              wayland
              gtk3
              dbus-glib
              glib
            ]
          );
        in
        ''
          patchelf --set-rpath "${libPath}" "$out/bin/ludusavi"
          wrapProgram $out/bin/ludusavi --prefix PATH : ${
            prev.lib.makeBinPath [
              final.rclone
              final.zenity
              final.libsForQt5.kdialog
            ]
          } \
            "''${gappsWrapperArgs[@]}"
        '';
    });
  };
}
