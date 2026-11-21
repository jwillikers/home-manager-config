#!/usr/bin/env bash
set -euo pipefail
# set -x

bedtime_start="20:55"
bedtime_end="06:00"

config_file="/etc/systemd-bedtime-timer/config.json"

if [ -f "$config_file" ]; then
  bedtime_start=$(jq --raw-output ".bedtime.start" "$config_file")
  bedtime_end=$(jq --raw-output ".bedtime.end" "$config_file")
fi

# Bedtime starts at bedtime_start, inclusive, and ends at bedtime_end.
is_bedtime() {
  local current_time
  current_time=$(date +%H:%M)
  ! [[ "$current_time" < "$bedtime_start" ]] || [[ "$current_time" < "$bedtime_end" ]]
}

notify_status() {
  if [ -n "${NOTIFY_SOCKET+x}" ]; then
    systemd-notify --ready --status="$1"
  else
    echo "$1"
  fi
}

# This runs as a system service, which has no session bus of its own.
# Send the notification to the session bus of every logged-in user instead.
# Notifications are best-effort and must never prevent suspending.
notify_users() {
  local notify_send env bus uid user
  notify_send=$(command -v notify-send)
  env=$(command -v env)
  for bus in /run/user/*/bus; do
    [ -S "$bus" ] || continue
    uid=$(basename "$(dirname "$bus")")
    user=$(id --name --user "$uid") || continue
    runuser --user "$user" -- "$env" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
      "$notify_send" --app-name=bedtime --urgency=critical --expire-time=30000 "$1" || true
  done
}

# Run only while it is bedtime, otherwise exit.
while :; do
  if is_bedtime; then
    notify_status "It's bedtime!"
    notify_users "Less than 5 minutes until bedtime"
    sleep 240 # 4 minutes
    notify_users "60 seconds until bedtime"
    sleep 60 # 1 minute
    systemctl suspend
  else
    notify_status "It is not bedtime. Exiting."
    exit 0
  fi
done
