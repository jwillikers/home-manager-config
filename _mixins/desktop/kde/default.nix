{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
{
  home = {
    file = {
      "${config.home.homeDirectory}/.gnupg/gpg-agent.conf".text = ''
        pinentry-program ${lib.getBin pkgs.kwalletcli}/bin/pinentry-kwallet
      '';
      # Go to System Settings > KDE Wallet and enable Use KWallet for the Secret Service interface. ??
      "${config.xdg.configHome}/kwalletrc" = {
        onChange = ''
          ${lib.getBin pkgs.kdePackages.qttools}/bin/qdbus org.kde.kwalletd6 /modules/kwalletd6 closeAllWallets
          ${lib.getBin pkgs.kdePackages.qttools}/bin/qdbus org.kde.kwalletd6 /modules/kwalletd6 open kdewallet 0 0
        '';
        text = ''
          [org.freedesktop.secrets]
          apiEnabled=true
        '';
      };
      "${config.xdg.dataHome}/dbus-1/services/org.freedesktop.secrets.service".text = ''
        [D-BUS Service]
        Name=org.freedesktop.secrets
        Exec=/usr/bin/kwalletd6
      '';
      "${config.xdg.dataHome}/konsole/Default.profile".text = ''
        [Appearance]
        ColorScheme=Solarized

        [General]
        Name=Default
        Parent=FALLBACK/
      '';
    };
    packages = with pkgs; [
      kdePackages.ksshaskpass
    ];
  };
  systemd.user = {
    services = {
      "ksshaskpass" = {
        Unit = {
          Description = "Add the SSH key to the SSH agent";
          After = [
            "graphical-session.target"
            "plasma-kwallet-pam.service"
            "plasma-polkit-agent.service"
            "ssh-agent.service"
          ];
          Requires = [
            "graphical-session.target"
            "plasma-kwallet-pam.service"
            "ssh-agent.service"
          ];
          Wants = [
            "plasma-polkit-agent.service"
          ];
        };

        Service = {
          Type = "oneshot";
          Environment = [
            "SSH_ASKPASS=${lib.getExe pkgs.kdePackages.ksshaskpass}"
            "SSH_AUTH_SOCK=%t/ssh-agent.socket"
          ];
          # For some reason the dependencies are not enough for this service to start successfully.
          # Add a delay to ensure it succeeds.
          ExecStartPre = "${lib.getBin pkgs.coreutils}/bin/sleep 15";
          ExecStart = "${lib.getBin pkgs.openssh}/bin/ssh-add -q";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
    sessionVariables = {
      # ksshaskpass
      SSH_ASKPASS = lib.getExe pkgs.kdePackages.ksshaskpass;
      SSH_ASKPASS_REQUIRE = "prefer";
    };
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
  xdg.portal = {
    config = {
      common = {
        default = [ "kde" ];
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
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
