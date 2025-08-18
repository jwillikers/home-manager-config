{
  config,
  desktop,
  lib,
  pkgs,
  ...
}:
{
  home = {
    file = {
      "${config.home.homeDirectory}/.gnupg/gpg-agent.conf".text =
        ""
        + lib.optionalString (desktop == "kde") ''
          pinentry-program ${lib.getBin pkgs.kwalletcli}/bin/pinentry-kwallet
        ''
        # Nix pinentry program crashes on Hyprland.
        # Use already installed pinentry package.
        + lib.optionalString (desktop == "hyprland") ''
          pinentry-program /usr/bin/pinentry-gnome3
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
        Exec=${lib.getBin pkgs.kwalletcli}/bin/kwalletd6
      '';
    };
    packages = with pkgs; [
      kwalletcli
      kdePackages.kwalletmanager
    ];
  };
  # gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-gnome3;
  # gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-qt;
  # services.gpg-agent.pinentry.package = lib.mkIf (desktop == "hyprland") pkgs.runCommandLocal "empty" { } "mkdir $out";
  xdg.portal = {
    config = {
      common = {
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
      };
    };
  };
  # Create our own service to initiate the kwallet pam service on Hyprland.
  # Wayblue uses kwallet for secret storage.
  systemd.user.services."plasma-kwallet-pam" = lib.mkIf (desktop == "hyprland") {
    Unit = {
      Description = "Unlock kwallet from pam credentials";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # Anything PAM-related has to be done outside of Nix.
      # Otherwise, things will most likely break because Nix and the OS might not agree on what PAM modules are available.
      ExecStart = "/usr/libexec/pam_kwallet_init";
      Type = "exec";
      Slice = "background.slice";
      Restart = false;
    };
    # todo Install?
  };
}
