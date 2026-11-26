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
    packages = with pkgs.unstable; [
      stretchly
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
        Requires = [
          "graphical-session.target"
        ]
        ++ lib.optionals (hostname == "steamdeck") [
          "plasma-workspace.target"
        ];
        Wants = lib.optionals (desktop == "hyprland") [ "waybar.service" ];
      };

      Service = {
        Type = "exec";
        # todo Is this sleep necessary?
        # Delay startup for a minute.
        # ExecStartPre = "${lib.getBin pkgs.coreutils}/bin/sleep 60";
        # Electron flags to force X11
        # ExecStart = "${lib.getExe pkgs.stretchly} --enable-features=UseOzonePlatform --ozone-platform=x11";
        # The flags below force Wayland
        # The Steam Deck still uses X11 in desktop mode by default, but I use the Wayland session.
        ExecStart = "-${lib.getExe pkgs.stretchly} --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandLinuxDrmSyncobj";
        # KillSignal = "SIGKILL";
        # KillMode = "control-group";
        Restart = "always";
        RestartSec = 10;
        TimeoutStartSec = 120;
        # todo Not sure how forking works, so not sure if the ExitType cgroup should be used.
        # Seems like this should be cgroup, since Stretchly spawns a background process and remains when not using cgroup KillMode.
        # ExitType = "cgroup";
      };

      Install = {
        WantedBy = [ "xdg-desktop-autostart.target" ];
      };
    };
    # Pause breaks during online meetings and while watching videos.
    # Meetings are detected by microphone use and videos by requests to keep the screen on.
    # Games are ignored so that breaks continue while gaming.
    # On the Steam Deck, also pause breaks while playing games locally with friends,
    # i.e. while at least two gamepads are connected, not counting the Steam Deck's own controls.
    #
    # Also pause breaks while away, and reset them on returning.
    # Otherwise, breaks keep opening while nobody is around, which wakes the screen and keeps it from locking.
    # Stretchly's natural breaks are disabled in its configs, since its idle detection doesn't work for this.
    # It doesn't count gamepad input on the Steam Deck, and it gets stuck on Hyprland,
    # leaving breaks paused as if idle while the computer is in use.
    # Instead, input-idle-monitor watches every input device, gamepads included, which requires the input group.
    # The idle threshold must be longer than the longest break, since pausing ends a break in progress,
    # and shorter than the time between breaks, so that the next break never opens while away.
    # Breaks last up to 4 minutes, 16 minutes apart, or 10 minutes, 25 minutes apart, on the Steam Deck.
    "stretchly-inhibit" = {
      Unit = {
        Description = "Pause Stretchly breaks during online meetings, while watching videos, and while away";
        After = [
          "pipewire-pulse.service"
          "stretchly.service"
        ];
        BindsTo = [
          "pipewire-pulse.service"
          "stretchly.service"
        ];
        Requires = [
          "pipewire-pulse.service"
          "stretchly.service"
        ];
        ConditionEnvironment = [
          "XDG_RUNTIME_DIR"
        ];
      };

      Service = {
        Type = "notify";
        ExecStart =
          let
            idleThreshold = if hostname == "steamdeck" then 900 else 600;
          in
          lib.concatStringsSep " " (
            [
              (lib.getExe pkgs.stretchly-inhibit)
              "--idle-monitor"
              (lib.escapeShellArg "${lib.getExe pkgs.input-idle-monitor} --threshold ${toString idleThreshold}")
            ]
            ++ lib.optionals (hostname == "steamdeck") [ "--pause-for-gamepads 2" ]
          );
        NotifyAccess = "all";
        Restart = "always";
        Slice = "background.slice";
      };

      Install = {
        WantedBy = [
          "stretchly.service"
        ];
      };
    };
  };

  # Place break windows on their respective monitors as soon as they open.
  # Load from the package so that its tests run when building the config.
  wayland.windowManager.hyprland.extraConfig = lib.mkIf (desktop == "hyprland") ''
    dofile("${pkgs.stretchly-hyprland}/share/stretchly-hyprland/stretchly-hyprland.lua")
  '';

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match = {
        class = "^(electron)$";
        title = "^(Stretchly)$";
      };
      float = true;
      idle_inhibit = "none";
      no_screen_share = true;
      no_shortcuts_inhibit = true;
      stay_focused = true;
    }
    # "nomaxsize, ${stretchlyBreak}"
    # "monitor DP-7, ${stretchlyBreak}"
    # "workspace w, ${stretchlyBreak}"
    # todo "idle_inhibit none, ${stretchlyBreak}"
    # todo "no_screen_share on, ${stretchlyBreak}"
    # todo "no_shortcuts_inhibit off, ${stretchlyBreak}"
    # "fullscreen, ${stretchlyBreak}"
    # "pin, ${stretchlyBreak}"
    # "noclosefor 10000, ${stretchlyBreak}"
    {
      match = {
        class = "^(electron)$";
        title = "^(Time to take a break!)$";
      };
      float = true;
      idle_inhibit = "none";
      no_screen_share = true;
      no_shortcuts_inhibit = true;
      stay_focused = true;
    }
    {
      match = {
        class = "^(s|Stretchly)$";
        title = "^(Time to take a break!)$";
      };
      float = true;
      idle_inhibit = "none";
      no_screen_share = true;
      no_shortcuts_inhibit = true;
      stay_focused = true;
    }
  ];
}
