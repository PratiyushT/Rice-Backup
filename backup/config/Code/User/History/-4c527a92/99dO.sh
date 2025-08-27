#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
PID_FILE="/tmp/iio-hyprland.pid"

# --- Hooks ---
on_tablet_mode() {
    echo "[hook] Tablet mode ON — starting rotation"
    MONITOR=eDP-1 iio-hyprland eDP-1 &
    echo $! > "$PID_FILE"
}

on_laptop_mode() {
    echo "[hook] Tablet mode OFF — stopping rotation"
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    hyprctl reload
}

# --- Find the correct event file ---
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

if [[ -z "$EVENT_FILE" || ! -e "$EVENT_FILE" ]]; then
    echo "[error] Could not find tablet mode switch device."
    exit 1
fi

echo "[info] Monitoring tablet mode on: $EVENT_FILE"

# --- Listen for changes ---
evtest "$EVENT_FILE" | while read -r line; do
    if [[ "$line" =~ "\(SW_TABLET_MODE\),\ value\ ([0-9]+)" ]]; then
        val="${BASH_REMATCH[1]}"
        if [[ "$val" == "1" ]]; then
            on_tablet_mode
        else
            on_laptop_mode
        fi
    fi
done
