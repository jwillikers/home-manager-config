_: {
  # home = {
  #   # packages = with pkgs; [ gcr ];
  #   sessionVariables = {
  #     SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  #   };
  # };

  services.gnome-keyring = {
    enable = true;
    components = [
      "ssh"
      "secrets"
    ];
  };

  # systemd.user = {
  #   services = {
  #     "gcr-ssh-agent" = {
  #       Unit = {
  #         Description = "GCR ssh-agent wrapper";
  #         Requires = [ "gcr-ssh-agent.socket" ];
  #       };

  #       Service = {
  #         Type = "simple";
  #         StandardError = "journal";
  #         Environment = [
  #           "SSH_AUTH_SOCK=%t/gcr/ssh"
  #         ];
  #         ExecStart = "${(config.lib.nixGL.wrap pkgs.gcr)}/libexec/gcr-ssh-agent %t/gcr";
  #         Restart = "on-failure";
  #       };

  #       Install = {
  #         Also = [ "gcr-ssh-agent.socket" ];
  #         WantedBy = [ "default.target" ];
  #       };
  #     };
  #   };
  #   sessionVariables = {
  #     SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  #   };
  #   sockets = {
  #     "gcr-ssh-agent" = {
  #       Unit = {
  #         Description = "GCR ssh-agent wrapper";
  #       };
  #       Socket = {
  #         Priority = 6;
  #         Backlog = 5;
  #         ListenStream = "%t/gcr/ssh";
  #         # ExecStartPost = "-${lib.getBin pkgs.systemdMinimal}/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/gcr/ssh";
  #         DirectoryMode = "0700";
  #       };
  #       Install = {
  #         WantedBy = [ "sockets.target" ];
  #       };
  #     };
  #   };
  # };

  # # Workaround issues with the Hyprland Home Manager module not setting systemd.user.sessionVariables
  # wayland.windowManager.hyprland.settings.env = [
  #   "SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/gcr/ssh"
  # ];

  xdg.portal = {
    config = {
      common = {
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };
}
