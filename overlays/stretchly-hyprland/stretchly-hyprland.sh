#!/usr/bin/env bash
set -euo pipefail
# set -x

# A script to orient Stretchly breaks on their respective monitors on Hyprland.
# It basically just moves an resizes windows to monitors based on the order they appear.
# Should probably do it based on resolutions to be precise.
# Stretchly must be configured to show breaks on all monitors.
# Adding additional window rules in hyprland.conf can help prevent skipping breaks.
# Here's an example of some additional window rules for Stretchly breaks.
#
# windowrule=pin, class:Stretchly, title:Time to take a break!
# windowrule=stayfocused, class:Stretchly, title:Time to take a break!
# windowrule=noclosefor 10000, class:Stretchly, title:Time to take a break!
# windowrule=noscreenshare, class:Stretchly, title:Time to take a break!
#
# Requires jq, hyprctl, socat, and systemd-notify.

# Example Hyprland socket output
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

open_stretchly_windows=()

echo "Hyprland socket is: $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# mapfile -t available_monitors < <(hyprctl monitors -j | jq --raw-output 'sort_by(.id) | reverse | .[].name')
mapfile -t available_monitors < <(hyprctl monitors -j | jq --raw-output '.[].name')
echo "available_monitors:" "${available_monitors[@]}"

# Detects when Stretchly break windows are displayed and moves them to the correct monitors.
function handle {
  # openwindow>>WINDOWADDRESS,WORKSPACENAME,WINDOWCLASS,WINDOWTITLE
  # openwindow>>be2ad50,9,Stretchly,Time to take a break!

  # todo handle attaching and detaching monitors
  if [[ ${1:0:10} == "openwindow" ]]; then
    # echo "command: ${1:0:10}"
    IFS="," read -r window_id _workspace_name window_class window_title <<< "${1:12}"
    # echo "window_id: $window_id"
    # echo "window_class: $window_class"
    if [[ $window_class == "Stretchly" ]]; then
      # window_title=${1##*,}
      echo "window_title: $window_title"
      if [[ $window_title == "Time to take a break!" ]]; then
        index=${#open_stretchly_windows[@]}
        echo "window index: $index"
        open_stretchly_windows+=( "$window_id" )
        echo "open_stretchly_windows: " "${open_stretchly_windows[@]}"
        if (( $index < ${#available_monitors[@]} )); then
          echo "Running: hyprctl --batch \"dispatch focuswindow address:0x$window_id ; dispatch movewindow mon:${available_monitors[$index]} ; dispatch centerwindow address:0x$window_id\""
          hyprctl --batch "dispatch focuswindow address:0x$window_id ; dispatch movewindow mon:${available_monitors[$index]} ; dispatch centerwindow address:0x$window_id"
          # hyprctl dispatch tagwindow "address:$window_id" "stretchly-break-${available_monitors[$index]}"
        fi
      fi
    fi
  elif [[ ${1:0:11} == "closewindow" ]]; then
    # echo "command: ${1:0:11}"
    window_id=${1:13}
    # echo "winwdow_id: $window_id"
    if [[ " ${open_stretchly_windows[*]} " =~ [[:space:]]${window_id}[[:space:]] ]]; then
      echo "Remove winwdow_id: $window_id"
      # Remove the window
      for i in "${!open_stretchly_windows[@]}"; do
        if [[ ${open_stretchly_windows[i]} = "$window_id" ]]; then
          unset 'open_stretchly_windows[i]'
        fi
      done
      # Update the array to have contiguous indices.
      for i in "${!open_stretchly_windows[@]}"; do
        new_array+=( "${open_stretchly_windows[i]}" )
      done
      open_stretchly_windows=("${new_array[@]}")
      unset new_array
      echo "open_stretchly_windows: " "${open_stretchly_windows[@]}"
    fi
  fi
}

if [ ! -z ${NOTIFY_SOCKET+x} ]; then
  systemd-notify --ready "--status=Monitoring Hyprland socket $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
fi

# Use -t 2147483647 in versions of socat 1.8.0.0-.2 https://stackoverflow.com/questions/79346955/how-to-set-infinite-timout-for-socat
socat -t 2147483647 - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done

echo "Should never reach here! Try running socat with -t 2147483647 instead of -t 0"
exit 1
