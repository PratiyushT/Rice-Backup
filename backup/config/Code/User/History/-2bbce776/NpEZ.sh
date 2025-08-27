#!/usr/bin/env bash
set -euo pipefail

ENABLE_FILE="${ENABLE_FILE:-$HOME/.config/linuxflip/autorotate.enabled}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
MONITOR_RESET_SPEC="${MONITOR_RESET_SPEC:-eDP-1,2880x1800@90.0,0x0,2.0}"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="${APP_NAME}" "$1" "$2"
  fi
}

set_normal_orientation() {
  hyprctl keyword monitor "${MONITOR_RESET_SPEC}" >/dev/null 2>&1 || true
  if command -v wlr-randr >/dev/null 2>&1; then
    wlr-randr --output "${DISPLAY_NAME}" --transform normal >/dev/null 2>&1 || true
  fi
}

mkdir -p "$(dirname "$ENABLE_FILE")"
[[ -f "$ENABLE_FILE" ]] || echo "1" > "$ENABLE_FILE"

state="$(cat "$ENABLE_FILE" || echo 1)"
if [[ "$state" == "1" ]]; then
  echo "0" > "$ENABLE_FILE"
  # Stop running autorotate if any
  if [[ -f "$PID_FILE" ]]; then
    pid="$(cat "$PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
  # Force eDP-1 back to your baseline immediately
  set_normal_orientation
  notify "Autorotate" "Disabled. eDP-1 reset."
else
  echo "1" > "$ENABLE_FILE"
  notify "Autorotate" "Enabled"
fi
