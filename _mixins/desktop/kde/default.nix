{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
{
  imports = [
    ./ksshaskpass
    ./kwallet
  ];

  home = {
    file = {
      "${config.xdg.dataHome}/konsole/Default.profile".text = ''
        [Appearance]
        ColorScheme=Solarized

        [General]
        Name=Default
        Parent=FALLBACK/
      '';
    };
  };
  systemd.user = {
    tmpfiles.rules = lib.mkIf (hostname == "steamdeck") [
      # Mask broken systemd units on the Steam Deck.
      #
      # app-firewall has a dependency problem with PyQt5
      # I don't know why the other two fail.
      "L+ ${config.xdg.configHome}/systemd/user/app-defaultbrightness@autostart.service - - - - /dev/null"
      "L+ ${config.xdg.configHome}/systemd/user/app-firewall\\x2dapplet@autostart.service - - - - /dev/null"
      "L+ ${config.xdg.configHome}/systemd/user/app-ibus@autostart.service - - - - /dev/null"
    ];
  };
  # wayland.systemd.target = "plasma-wayland-session.target";
  xdg.portal = {
    config = {
      common = {
        default = [ "kde" ];
      };
      kde = {
        default = [ "kde" ];
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
      };
    };
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };
}
