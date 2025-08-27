#!/usr/bin/env bash
set -euo pipefail

ENABLE_FILE="${ENABLE_FILE:-$HOME/.config/linuxflip/autorotate.enabled}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="${APP_NAME}" "$1" "$2"
  fi
}

mkdir -p "$(dirname "$ENABLE_FILE")"
[[ -f "$ENABLE_FILE" ]] || echo "1" > "$ENABLE_FILE"

state="$(cat "$ENABLE_FILE" || echo 1)"
if [[ "$state" == "1" ]]; then
  echo "0" > "$ENABLE_FILE"
  # If running, stop it
  if [[ -f "$PID_FILE" ]]; then
    pid="$(cat "$PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
  notify "Autorotate" "Disabled"
else
  echo "1" > "$ENABLE_FILE"
  notify "Autorotate" "Enabled"
fi
