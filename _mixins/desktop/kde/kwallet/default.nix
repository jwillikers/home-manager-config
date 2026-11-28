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
        # KWallet no longer ships pinentry-kwallet, and nothing in nixpkgs provides it,
        # so use the Qt pinentry program, which fits the rest of the Plasma desktop.
        # A pinentry-program which doesn't exist fails every attempt to sign or decrypt
        # with "gpg: signing failed: No pinentry", so this has to point at a real binary.
        + lib.optionalString (desktop == "kde") ''
          pinentry-program ${lib.getBin pkgs.pinentry-qt}/bin/pinentry-qt
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
        Exec=${lib.getBin pkgs.kdePackages.kwallet}/bin/kwalletd6
      '';
    };
    packages = with pkgs; [
      kdePackages.kwallet
      kdePackages.kwalletmanager
    ];
  };
  # gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-gnome3;
  # gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-qt;
  # services.gpg-agent.pinentry.package = lib.mkIf (desktop == "hyprland") pkgs.runCommandLocal "empty" { } "mkdir $out";
  # pam_kwallet_init hands the login credentials to kwalletd over a socket that only works once per login.
  # Plasma's own unit is Type=simple with no RemainAfterExit, so it falls back to inactive once the handoff
  # is done and runs again whenever something wants it, such as ksshaskpass restarting during a
  # home-manager switch, which always fails with "Connection refused" on the spent socket.
  # Keep it active after the handoff instead, so nothing starts it a second time.
  # On Hyprland the unit below already does this, since Wayblue has no Plasma unit to drop in on.
  xdg.configFile = lib.mkIf (desktop == "kde") {
    "systemd/user/plasma-kwallet-pam.service.d/remain-after-exit.conf".text = ''
      [Service]
      RemainAfterExit=true
    '';
  };
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
      # pam_kwallet_init hands the login credentials to kwalletd over a socket that only works once per login.
      # Don't let a home-manager switch run it again, since that always fails.
      X-RestartIfChanged = false;
    };
    Service = {
      # Anything PAM-related has to be done outside of Nix.
      # Otherwise, things will most likely break because Nix and the OS might not agree on what PAM modules are available.
      ExecStart = "/usr/libexec/pam_kwallet_init";
      # Stay active after the one-time handoff so units that require this one, like ksshaskpass, don't start it again.
      Type = "oneshot";
      RemainAfterExit = true;
      Slice = "background.slice";
      Restart = "no";
    };
    # todo Install?
  };
}
