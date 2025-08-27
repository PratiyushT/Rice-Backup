#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"

# Step 1: Find the event file
EVENT_FILE=$(
  awk -v target="$DEVICE_NAME" '
    BEGIN { RS=""; FS="\n" }
    {
      match_name=0
      event=""
      for (i=1; i<=NF; i++) {
        if ($i ~ "^N: Name=\"" target "\"") match_name=1
        if ($i ~ /^H: Handlers=/ && match($i, /event[0-9]+/, m)) event=m[0]
      }
      if (match_name && event != "") {
        print "/dev/input/" event
        exit
      }
    }
  ' /proc/bus/input/devices
)

# Step 2: Show the file name
if [[ -n "$EVENT_FILE" && -e "$EVENT_FILE" ]]; then
  echo "[info] Found device: $EVENT_FILE"
else
  echo "[error] Device not found"
  exit 1
fi

# Step 3: Show its live content
echo "[info] Starting evtest on $EVENT_FILE"
exec evtest "$EVENT_FILE"
