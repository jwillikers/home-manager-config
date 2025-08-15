{
  desktop,
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      kdePackages.ksshaskpass
    ];
    sessionVariables = {
      SSH_ASKPASS = lib.getExe pkgs.kdePackages.ksshaskpass;
      SSH_ASKPASS_REQUIRE = "prefer";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    };
  };

  systemd.user = {
    services = {
      "ksshaskpass" = {
        Unit = {
          Description = "Add the SSH key to the SSH agent";
          After = [
            "graphical-session.target"
            "ssh-agent.service"
          ]
          ++ lib.optionals (desktop == "kde") [
            "plasma-kwallet-pam.service"
            "plasma-polkit-agent.service"
          ]
          ++ lib.optionals (desktop == "hyprland") [
            "hyprland-session.target"
          ];
          Requires = [
            "graphical-session.target"
            "ssh-agent.service"
          ]
          ++ lib.optionals (desktop == "kde") [
            "plasma-kwallet-pam.service"
          ];
          Wants = lib.mkIf (desktop == "kde") [
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
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    };
  };

  # Workaround issues with the Hyprland Home Manager module not setting systemd.user.sessionVariables
  wayland.windowManager.hyprland.settings.env = [
    "SSH_ASKPASS,${lib.getExe pkgs.kdePackages.ksshaskpass}"
    "SSH_ASKPASS_REQUIRE,prefer"
    "SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/ssh-agent.socket"
  ];
}
