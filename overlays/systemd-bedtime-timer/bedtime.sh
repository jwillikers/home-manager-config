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

# Run only while it is not bedtime, otherwise exit.
while :; do
  current_time=$(date +%H:%M)
  if [[ "$current_time" > "$bedtime_start" ]] || [[ "$current_time" < "$bedtime_end" ]]; then
    if [ ! -z ${NOTIFY_SOCKET+x} ]; then
      systemd-notify --ready --status="It's bedtime!"
    else
      echo "It's bed time."
    fi
    notify-send --app-name=bedtime --urgency=critical --expire-time=30000 --urgency=critical "Less than 5 minutes until bedtime"
    sleep 240 # 4 minutes
    notify-send --app-name=bedtime --urgency=critical --expire-time=30000 --urgency=critical "60 seconds until bedtime"
    sleep 60 # 1 minute
    systemctl suspend
  else
    if [ ! -z ${NOTIFY_SOCKET+x} ]; then
      systemd-notify --ready status="It is not bed time. Exiting."
    else
      echo "It is not bed time. Exiting."
    fi
    exit 0
  fi
done
