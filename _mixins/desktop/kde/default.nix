{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    file = {
      ".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${lib.getBin pkgs.kwalletcli}/bin/pinentry-kwallet
      '';
      # Go to System Settings > KDE Wallet and enable Use KWallet for the Secret Service interface. ??
      "${config.xdg.dataHome}/dbus-1/services/org.freedesktop.secrets.service".text = ''
        [D-BUS Service]
        Name=org.freedesktop.secrets
        Exec=/usr/bin/kwalletd6
      '';
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
            "ssh-agent.service"
          ];
          Requires = [
            "graphical-session.target"
            "plasma-kwallet-pam.service"
            "ssh-agent.service"
          ];
        };

        Service = {
          Type = "oneshot";
          Environment = [
            "SSH_ASKPASS=${lib.getExe pkgs.kdePackages.ksshaskpass}"
            "SSH_AUTH_SOCK=%t/ssh-agent.socket"
          ];
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
