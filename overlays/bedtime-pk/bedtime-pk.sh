#!/usr/bin/env bash
set -euo pipefail

# bedtime-pk aka bedtime process killer is a simple utility for monitoring and killing specific processes during bedtime.

# Requires Bash, awk, systemd-notify, loginctl, date, and xdotool and xprop on X11.
# On Hyprland, requires hyprctl and the Hyprland socket2 to monitor for specific windows.
# Currently intended for KDE on X11 and Wayland, and Hyprland

# todo Monitor plain processes based on regex from a list in a file.

# todo To abort execution of certain utilities during bedtime, use specialized wrapper scripts.

# For process monitoring:
# inotifywait
# inotifywait -m -e access,close_nowrite --format=%e /bin/ls
# auditd
# https://unix.stackexchange.com/questions/688478/how-do-i-run-command-hooks-when-a-specific-process-is-started
# https://doc.opensuse.org/documentation/leap/archive/15.0/security/html/book.security/cha.audit.comp.html#sec.audit.audisp

bedtime_start="21:14"
bedtime_end="06:59"

# Run forever.
while :; do
  current_time=$(date +%H:%M)
  if [[ "$current_time" > "$bedtime_start" ]] || [[ "$current_time" < "$bedtime_end" ]]; then
    if [ ! -z ${NOTIFY_SOCKET+x} ]; then
      systemd-notify --ready --status="Monitoring for bedtime processes"
    else
      echo "It's bed time. Monitoring for bedtime processes"
    fi
    session=$(loginctl show-session "$(loginctl | grep seat0 | awk '{print $1}')" --property=Type --value)
    if [ "$session" == "x11" ]; then
      # Assuming xdotool and xprop are available
      active_window_id=$(xdotool getwindowfocus)
      echo "active_window_id: $active_window_id"

      # Check if the window is in fullscreen mode
      is_fullscreen=$(xprop -id "$active_window_id" _NET_WM_STATE | grep _NET_WM_STATE_FULLSCREEN)
      echo "is_fullscreen: $is_fullscreen"

      # todo, Should probably check window name regardless of whether or not it is fullscreen.
      if [[ -n "$is_fullscreen" ]]; then
          window_name=$(xprop -id "$active_window_id" WM_NAME | awk -F '"' '{print $2}')
          if [[ "$window_name" =~ "Lutris"|"Steam"|"Game"|"Engine"|"vulkan"|"opengl" ]]; then
            echo "The fullscreen application '$window_name' likely to be a game is running. Killing."
          else
            echo "The fullscreen application '$window_name' is running, but it may not be a game. Killing anyways."
          fi
          xdotool getwindowfocus windowkill
      else
        # todo Check for other potential processes / Windows.
        echo "No fullscreen application is active."
      fi
      else
        # todo Check for other potential processes / Windows.
        echo "The session is not X11."
    fi
    sleep 130 # 2.5 minutes
  else
    if [ ! -z ${NOTIFY_SOCKET+x} ]; then
      systemd-notify --ready status="It is not bed time. Exiting."
    else
      echo "It is not bed time. Exiting."
    fi
    exit 0
  fi
done

# todo Use a kwin script for KDE?
# https://develop.kde.org/docs/plasma/kwin/
# // This is a simplified example, not a runnable script.
# const { workspace } = require('kwin');
# workspace.windowActivated.connect((window) => {
#     if (window.fullscreen) {
#         // Broadcast a signal or write to a log that a fullscreen app is active.
#         // E.g., send DBus message: "dbus-send --print-reply --session --dest=com.your.app /GameDetector org.GameDetector.GamePlaying boolean:true"
#     }
# });
