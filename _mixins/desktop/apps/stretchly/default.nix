{
  config,
  desktop,
  hostname,
  lib,
  packages,
  pkgs,
  ...
}:
# Break timer
{
  home = {
    # Symlinking the Stretchly config won't work.
    # It's also necessary to install the config when Stretchly isn't running.
    activation.stretchly = lib.hm.dag.entryAfter [ "flatpaks" ] (
      let
        stretchly-config =
          if hostname == "steamdeck" then packages.stretchly-steam-deck-config else packages.stretchly-config;
      in
      ''
        # We don't want the cmp command to cause the script to fail.
        set +e
        cmp --silent \
          "${stretchly-config}/etc/Stretchly/config.json" \
          "${config.xdg.configHome}/Stretchly/config.json"
        exit_status=$?
        set -e
        if [ $exit_status -eq 1 ]; then
          service_running=0
          if ${lib.getBin pkgs.procps}/bin/pgrep --full --ignore-case Stretchly >/dev/null; then
            if ${lib.getBin pkgs.systemdMinimal}/bin/systemctl --user is-active stretchly.service >/dev/null; then
              service_running=1
              run ${lib.getBin pkgs.systemdMinimal}/bin/systemctl --user stop stretchly.service
            else
              run ${lib.getBin pkgs.procps}/bin/pkill --full --ignore-case Stretchly
            fi
          else
            run ${lib.getBin pkgs.util-linux}/bin/setsid ${lib.getExe pkgs.stretchly} &>/dev/null &
            run ${lib.getBin pkgs.coreutils}/bin/sleep 10
            run ${lib.getBin pkgs.procps}/bin/pkill --full --ignore-case Stretchly
          fi
          run ${lib.getBin pkgs.coreutils}/bin/sleep 1
          run mkdir --parents ${config.xdg.configHome}/Stretchly/
          run install -D --mode=0644 $VERBOSE_ARG \
              "${stretchly-config}/etc/Stretchly/config.json" \
              "${config.xdg.configHome}/Stretchly/config.json"
          if [ "$service_running" -eq 1 ]; then
            run ${pkgs.systemdMinimal}/bin/systemctl --user start stretchly.service
          else
            run ${lib.getBin pkgs.util-linux}/bin/setsid ${lib.getExe pkgs.stretchly} &>/dev/null &
          fi
        fi
      ''
    );
    packages = with pkgs; [
      (config.lib.nixGL.wrap stretchly)
    ];
  };
  systemd.user.services = {
    "stretchly" = {
      Unit = {
        Description = "Start Stretchly";
        After = [
          "graphical-session.target"
        ]
        ++ lib.optionals (desktop == "hyprland") [
          "waybar.service"
        ]
        ++ lib.optionals (hostname == "steamdeck") [
          "plasma-workspace.target"
        ];
        BindsTo = [
          "graphical-session.target"
        ]
        # When switching back to Gaming Mode on the Steam Deck, Stretchly won't be closed if it only requires graphical-session.target.
        # It also needs to depend on Plasma so that Stretchly is closed along with Plasma when switching back to Gaming Mode.
        # Without this, the Steam Deck will hang with a blank screen and cursor when switching from Desktop Mode to Gaming Mode.
        # todo See if BindsTo no longer requires this dependency here or if the graphical-session.target stays up anyways.
        ++ lib.optionals (hostname == "steamdeck") [
          "plasma-workspace.target"
        ];
        Wants = lib.optionals (desktop == "hyprland") [ "waybar.service" ];
      };

      Service = {
        Type = "exec";
        ExecStartPre = "${lib.getBin pkgs.coreutils}/bin/sleep 1";
        # Electron flags to force X11
        # ExecStart = "${lib.getExe pkgs.stretchly} --enable-features=UseOzonePlatform --ozone-platform=x11";
        # The flags below force Wayland
        ExecStart = "-${lib.getExe pkgs.stretchly} --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandLinuxDrmSyncobj";
        KillSignal = "SIGKILL";
        KillMode = "mixed";
        Restart = "always";
        RestartSec = 10;
        # todo Not sure how forking works, so not sure if the ExitType cgroup should be used.
        # ExitType = "cgroup";
      };

      Install = {
        WantedBy = [ "xdg-desktop-autostart.target" ];
      };
    };
    "stretchly-hyprland" = lib.mkIf (desktop == "hyprland") {
      Unit = {
        Description = "Move Stretchly break windows to multiple monitors in Hyprland";
        After = [
          "hyprland-session.target"
          "stretchly.service"
        ];
        BindsTo = [
          "hyprland-session.target"
          "stretchly.service"
        ];
        ConditionEnvironment = [
          "HYPRLAND_INSTANCE_SIGNATURE"
          "XDG_RUNTIME_DIR"
        ];
      };

      Service = {
        Type = "notify";
        ExecStart = lib.getExe pkgs.stretchly-hyprland;
        NotifyAccess = "all";
        Restart = "always";
        Slice = "background.slice";
      };

      Install = {
        WantedBy = [
          "hyprland-session.target"
          "xdg-desktop-autostart.target"
        ];
      };
    };
  };

  wayland.windowManager.hyprland.settings.windowrule =
    let
      stretchlyBreak = "class:Stretchly, title:Time to take a break!";
    in
    [
      # "nomaxsize, ${stretchlyBreak}"
      # "monitor DP-7, ${stretchlyBreak}"
      # "float, ${stretchlyBreak}"
      # "fullscreen, ${stretchlyBreak}"
      "pin, ${stretchlyBreak}"
      "stayfocused, ${stretchlyBreak}"
      "noclosefor 10000, ${stretchlyBreak}"
      "noscreenshare, ${stretchlyBreak}"
    ];
}
