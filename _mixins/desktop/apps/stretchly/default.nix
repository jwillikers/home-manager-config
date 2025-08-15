{
  config,
  hostname,
  lib,
  packages,
  pkgs,
  ...
}:
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
      (config.lib.nixGL.wrap stretchly) # Break timer
    ];
  };
  systemd.user.services = {
    "stretchly" = {
      Unit = {
        Description = "Start Stretchly";
        After = [
          "graphical-session.target"
        ]
        # When switching back to Gaming Mode on the Steam Deck, Stretchly won't be closed if it only requires graphical-session.target.
        # It also needs to depend on Plasma so that Stretchly is closed along with Plasma when switching back to Gaming Mode.
        # Without this, the Steam Deck will hang with a blank screen and cursor when switching from Desktop Mode to Gaming Mode.
        ++ lib.optionals (hostname == "steamdeck") [
          "plasma-workspace.target"
        ];
        Requires = [
          "graphical-session.target"
        ]
        ++ lib.optionals (hostname == "steamdeck") [
          "plasma-workspace.target"
        ];
      };

      Service = {
        Type = "exec";
        ExecStartPre = "${lib.getBin pkgs.coreutils}/bin/sleep 1";
        # Add Electron flags to force X11
        # --ozone-platform-hint=wayland
        # ExecStart = "${lib.getExe pkgs.stretchly} --enable-features=UseOzonePlatform --ozone-platform=x11";
        # The flags below force Wayland
        ExecStart = "${lib.getExe pkgs.stretchly} --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandLinuxDrmSyncobj";
        KillMode = "mixed";
        Restart = "always";
        RestartSec = 10;
        ExitType = "cgroup";
        # Don't trust Stretchly's exit code since it crashes when killed.
        SuccessExitStatus = [
          "SUCCESS"
          "NOTRUNNING"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  wayland.windowManager.hyprland.settings.windowrule =
    let
      stretchlyBreak = "class:Stretchly, title:Time to take a break!";
    in
    [
      "monitor DP-7, ${stretchlyBreak}"
      "float, ${stretchlyBreak}"
      "pin, ${stretchlyBreak}"
      "fullscreen, ${stretchlyBreak}"
      "stayfocused, ${stretchlyBreak}"
      "noclosefor 10000, ${stretchlyBreak}"
      # "noscreenshare, ${stretchlyBreak}"
    ];
}
