#!/usr/bin/env bash
set -euo pipefail

# This script inhibits stretchly breaks while any source-outputs are running.
# In my case, source-outputs are typically relegated to microphones.
# In other words, breaks are paused when a microphone is open.

if [ ! -z ${NOTIFY_SOCKET+x} ]; then
  systemd-notify --ready --status="Monitoring PulseAudio server for events"
fi

if [[ $(pactl list source-outputs short) ]]; then
  echo "A source-output stream is active. Pausing Stretchly breaks."
  stretchly pause &>/dev/null
else
  echo "No source-output streams are open. Resuming Stretchly breaks."
  stretchly resume &>/dev/null
fi

pactl subscribe | while read -r _ event _ type _num; do
  # For checking if audio is playing, check for the sink-input type.
  # if [ "$event" == "'new'" ] && { [ "$type" == "sink-input" ] || [ "$type" == "source-output" ]; }; then
  if [ "$event" == "'new'" ] && [ "$type" == "source-output" ]; then
    echo "A new source-output has been opened. Pausing Stretchly breaks."
    stretchly pause &>/dev/null
  elif [ "$event" == "'remove'" ] && [ "$type" == "source-output" ]; then
    echo "A source-output stream has been closed."
    if [[ $(pactl list source-outputs short) ]]; then
      echo "A source-output stream is still active."
    else
      echo "No source-output streams are open. Resuming Stretchly breaks."
      stretchly resume &>/dev/null
    fi
  fi
done
