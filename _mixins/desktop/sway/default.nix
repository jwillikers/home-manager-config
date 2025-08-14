{
  config,
  lib,
  packages,
  pkgs,
  ...
}:
{
  home = {
    file = {
      "${config.xdg.configHome}/sway/config.d" = {
        onChange = "${lib.getBin pkgs.sway}/bin/swaymsg reload";
        source = packages.sway-config + "/etc/sway/config.d";
      };
    };
    packages = with pkgs; [
      sway-audio-idle-inhibit # Pause SwayLock when audio is playing
    ];
  };
  services = {
    gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-gnome3;
  };
  systemd.user = {
    sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # gcr
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    };
  };
  xdg.portal = {
    config = {
      common = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
    enable = true;
    extraPortals = with pkgs; [
      # xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
}
