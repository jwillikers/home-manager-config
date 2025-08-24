#!/usr/bin/env bash
set -euo pipefail
# set -x

# A script to orient Stretchly breaks on their respective monitors on Hyprland.
# It basically just moves windows to monitors, based on their respective sizes.
#
# Stretchly must be configured to show breaks on all monitors.
# Adding additional window rules in hyprland.conf can help prevent skipping breaks.
# Here's an example of some additional window rules for Stretchly breaks.
#
# windowrule=pin, class:Stretchly, title:Time to take a break!
# windowrule=stayfocused, class:Stretchly, title:Time to take a break!
# windowrule=noclosefor 10000, class:Stretchly, title:Time to take a break!
# windowrule=noscreenshare, class:Stretchly, title:Time to take a break!
#
# Requires bc, jq, hyprctl, socat, and when run from systemd, systemd-notify.
#
# This Bash script is slow and takes a couple of seconds to position the monitors after the breaks have started.
# Ideally this would happen immediately, but this is in part due to processing every single event from Hyprland and using an interpreted language like Bash.
# I should probably consider making a plugin and/or using a compiled language to speed things up.
# Or maybe I can just get this fixed in Hyprland or Electron/Stretchly?

# Example Hyprland socket output.
#
# activewindowv2>>be1f970
# windowtitle>>be2ad50
# windowtitlev2>>be2ad50,Time to take a break!
# windowtitle>>be181f0
# windowtitlev2>>be181f0,Time to take a break!
# openwindow>>be181f0,9,Stretchly,Time to take a break!
# activewindow>>Stretchly,Time to take a break!
# activewindowv2>>be181f0
# openwindow>>be2ad50,9,Stretchly,Time to take a break!
# focusedmon>>eDP-1,2
# focusedmonv2>>eDP-1,2
# activewindow>>Stretchly,Time to take a break!
# activewindowv2>>be2ad50
# activewindow>>Stretchly,Time to take a break!
# activewindowv2>>be181f0
# activewindow>>Stretchly,Time to take a break!
# activewindowv2>>be2ad50
# activewindow>>Stretchly,Time to take a break!
# activewindowv2>>be181f0
# activewindow>>Stretchly,Time to take a break!
# activewindowv2>>be2ad50
# closewindow>>be2ad50
# closewindow>>be181f0

function calculate_euclidean_distance {
  local x1
  local dx
  local dy
  local dist_sq
  local distance
  x1=$1 y1=$2 x2=$3 y2=$4
  dx=$(echo "$x2 - $x1" | bc --mathlib)
  dy=$(echo "$y2 - $y1" | bc --mathlib)
  dist_sq=$(echo "$dx*$dx + $dy*$dy" | bc --mathlib)
  distance=$(echo "sqrt($dist_sq)" | bc --mathlib)
  echo "$distance"
}

declare -A open_stretchly_windows=()

echo "Hyprland socket is: $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

function update_monitors {
  readarray -t monitors < <(hyprctl monitors -j | jq --compact-output 'map({id, name, width, height}) | sort_by(.id) | .[]')
}

update_monitors
echo "Monitors:" "${monitors[@]}"

available_monitors=( "${monitors[@]}" )

# Detects when Stretchly break windows are displayed and moves them to the correct monitors.
function handle {
  # openwindow>>WINDOWADDRESS,WORKSPACENAME,WINDOWCLASS,WINDOWTITLE
  # openwindow>>be2ad50,9,Stretchly,Time to take a break!

  # todo:
  # Wait for all of the open windows before moving them to their matching windows?
  # This avoids missing open window events while commands are being sent to Hyprland?
  if [[ ${1:0:10} == "openwindow" ]]; then
    # echo "command: ${1:0:10}"
    IFS="," read -r window_id _workspace_name window_class window_title <<< "${1:12}"
    # echo "window_id: $window_id"
    # echo "window_class: $window_class"
    if [[ $window_class == "Stretchly" ]]; then
      # window_title=${1##*,}
      echo "window_title: $window_title"
      # Sometimes, the window title is just "Stretchly" for some reason.
      if [[ $window_title == "Time to take a break!" ]] || [[ $window_title == "Stretchly" ]]; then
        # echo "window index: $index"

        # Get the width and height of the window.
        local width
        local height
        {
          read -r width
          read -r height
        } < <(hyprctl clients -j | jq --raw-output ".[] | select(.address == \"0x$window_id\").size | .[0], .[1]")

        local min_distance
        local min_monitor
        # Price is right rules
        for monitor in "${available_monitors[@]}"; do
          local monitor_name
          monitor_name=$(jq --raw-output '.name' <<< "$monitor")
          echo "monitor_name: $monitor_name"
          local monitor_width
          monitor_width=$(jq --raw-output '.width' <<< "$monitor")
          echo "monitor_width: $monitor_width"
          local monitor_height
          monitor_height=$(jq --raw-output '.height' <<< "$monitor")
          echo "monitor_height: $monitor_height"

          if (( width > monitor_width )) || (( height > monitor_height )); then
            continue
          fi

          local distance
          distance=$(calculate_euclidean_distance "$width" "$height" "$monitor_width" "$monitor_height")
          echo "distance: $distance"

          if [ -z ${min_distance+x} ] || (( $(echo "$distance < $min_distance" | bc --mathlib) )); then
            min_monitor=$monitor_name
            min_distance=$distance
          fi
        done

        echo "Matched window $window_id with monitor $min_monitor"
        open_stretchly_windows[$window_id]="$min_monitor"
        echo "open_stretchly_windows: " "${open_stretchly_windows[@]}"

        # Remove min_monitor from available_monitors
        for i in "${!available_monitors[@]}"; do
          local monitor_name
          monitor_name=$(jq --raw-output '.name' <<< "${available_monitors[i]}")
          if [[ "$monitor_name" = "$min_monitor" ]]; then
            unset 'available_monitors[i]'
            break
          fi
        done
        echo "available_monitors: " "${available_monitors[@]}"

        echo "Running: hyprctl --batch \"dispatch focuswindow address:0x$window_id ; dispatch movewindow mon:${open_stretchly_windows[$window_id]} ; dispatch centerwindow address:0x$window_id\""
        hyprctl --batch "dispatch focuswindow address:0x$window_id ; dispatch movewindow mon:${open_stretchly_windows[$window_id]} ; dispatch centerwindow address:0x$window_id"
        # Add the following command to tag the window with the monitor.
        # dispatch tagwindow ${open_stretchly_windows[$window_id] [address:0x$window_id]
      fi
    fi
  elif [[ ${1:0:11} == "closewindow" ]]; then
    # echo "command: ${1:0:11}"
    window_id=${1:13}
    # echo "winwdow_id: $window_id"
    if [ "${open_stretchly_windows[$window_id]+x}" ]; then
      echo "Remove window_id: $window_id"

      # Add the monitor back to available monitors.
      for i in "${!monitors[@]}"; do
        local monitor_name
        monitor_name=$(jq --raw-output '.name' <<< "${monitors[i]}")
        # echo "monitor_name: $monitor_name"
        # echo "assigned monitor: ${open_stretchly_windows[$window_id]}"
        if [[ "$monitor_name" = "${open_stretchly_windows[$window_id]}" ]]; then
          available_monitors+=( "${monitors[$i]}" )
          break
        fi
      done
      echo "available_monitors: " "${available_monitors[@]}"

      # Remove the window
      for i in "${!open_stretchly_windows[@]}"; do
        # echo "i: $i"
        if [[ "$i" = "$window_id" ]]; then
          unset 'open_stretchly_windows[$i]'
          break
        fi
      done
      echo "open_stretchly_windows: " "${open_stretchly_windows[@]}"
    fi
  # todo Handle interruptions during the time when setting the monitors for the windows?
  # There is a race condition between receiving an event here and polling hyprctl for the updated list of monitors.
  # This could lead to inconsistencies, so all monitors are refreshed every time there is a change.
  # Because of this, it's not possible to elegantly handle monitor changes while break windows are being assigned to monitors.
  # Things probably won't work quite right if that happens, depending on how Stretchly handles that case.
  elif [[ ${1:0:14} == "monitoraddedv2" ]] || [[ ${1:0:16} == "monitorremovedv2" ]]; then
    # todo Test this.
    echo "Monitors have changed. Updating monitors."
    update_monitors
    echo "Updated monitors:" "${monitors[@]}"
    available_monitors=( "${monitors[@]}" )
    echo "Available monitors:" "${available_monitors[@]}"
  fi
}

if [ ! -z ${NOTIFY_SOCKET+x} ]; then
  systemd-notify --ready "--status=Monitoring Hyprland socket $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
fi

# Use -t 2147483647 in versions of socat 1.8.0.0-.2 https://stackoverflow.com/questions/79346955/how-to-set-infinite-timout-for-socat
socat -t 2147483647 - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done

echo "Should never reach here! Try running socat with -t 2147483647 instead of -t 0"
exit 1
