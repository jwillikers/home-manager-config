{
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    # On the Precision 5350, even exposing the NVIDIA proprietary drivers results in Hyprland failing to launch.
    # This occurs regardless of the graphics cards allowed for Hyprland.
    package = pkgs.hyprland;
    # https://www.reddit.com/r/NixOS/comments/1gkrota/nixos_nvidia_hyprland_vscode_blinking/
    # package = pkgs.hyprland.override {
    #   wrapRuntimeDeps = false;
    # };
    settings.env = [
      # NVIDIA
      # https://wiki.hypr.land/Configuring/Environment-variables/#nvidia-specific
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "NVD_BACKEND,direct"

      # This order is necessary on the Precision 5350.
      # No other order works.
      "AQ_DRM_DEVICES,/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu"

      #"LIBVA_DRIVER_NAME,nvidia"

      # Uses dedicated udev rules for consistent device paths
      #"AQ_DRM_DEVICES,/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu"
      #"AQ_DRM_DEVICES,/dev/dri/nvidia-dgpu"
      #"AQ_FORCE_LINEAR_BLIT,0"

      # "GBM_BACKEND,nvidia-drm"
      "__GL_GSYNC_ALLOWED,1"
      "__GL_VRR_ALLOWED,0"
    ];
  };
}
