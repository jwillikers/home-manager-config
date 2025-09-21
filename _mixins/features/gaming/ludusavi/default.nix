{
  config,
  hostname,
  lib,
  packages,
  pkgs,
  ...
}:
# todo Use the Home Manager integration for Ludusavi.
let
  installOn = [
    "precision5350"
    "steamdeck"
    "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home = {
    file = {
      # Copy the file to make it writeable.
      "${config.xdg.configHome}/ludusavi/config_source.yaml" = {
        source =
          let
            ludusavi-config =
              if hostname == "steamdeck" then packages.ludusavi-steam-deck-config else packages.ludusavi-config;
          in
          ludusavi-config + "/etc/ludusavi/config.yaml";
        onChange = ''cat ${config.xdg.configHome}/ludusavi/config_source.yaml > ${config.xdg.configHome}/ludusavi/config.yaml'';
      };
    };
    packages = with pkgs; [
      (config.lib.nixGL.wrap ludusavi) # Game save data backup tool
      (writeShellApplication {
        name = "heroic-ludusavi-wrapper.sh";
        runtimeInputs = [ pkgs.ludusavi ];
        # Need to run flatpak override to permit access?
        text = ''
          ludusavi --config "$HOME/.config/ludusavi" wrap --force --infer heroic --no-force-cloud-conflict --gui -- "$@"
        '';
      })
    ];
  };
  systemd.user = {
    services = {
      "ludusavi" = {
        Unit = {
          Description = "Back up game save data with Ludusavi";
          After = [
            # "graphical-session.target"
            "nss-lookup.target"
            "sops-nix.service" # For Rclone password
          ];
          Requires = [ "sops-nix.service" ];
          # ConditionPathIsDirectory = ["%h/ludusavi-backup"];
          # Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "exec";
          ExecStart = "${lib.getExe pkgs.ludusavi} backup --force";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
          Slice = "background.slice";
        };
      };
    };
    tmpfiles.rules = [
      "v ${config.home.homeDirectory}/ludusavi-backup 0750 ${config.home.username} ${config.home.username} - -"
    ];
    timers = {
      "ludusavi" = {
        Unit = {
          Description = "Back up game save data with Ludusavi regularly";
        };

        Timer = {
          OnCalendar = "hourly";
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
