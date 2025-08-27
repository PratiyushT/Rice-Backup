#!/usr/bin/env bash
set -euo pipefail

DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"

# Flags
ENABLE_FILE="${ENABLE_FILE:-$HOME/.config/linuxflip/autorotate.enabled}"        # 1/0
ALWAYS_ON_FILE="${ALWAYS_ON_FILE:-$HOME/.config/linuxflip/autorotate.always_on}"# 1/0

ICON_TABLET="/Wallbash-Icon/media/knob-75.svg"
ICON_LAPTOP="/Wallbash-Icon/media/knob-25.svg"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="${APP_NAME}" --icon="$1" \
      --hint=string:x-canonical-private-synchronous:"${APP_NAME}-status" \
      "$2" "$3"
  fi
}

is_enabled()    { [[ -f "$ENABLE_FILE"    ]] && [[ "$(cat "$ENABLE_FILE")"    == "1" ]]; }
is_always_on()  { [[ -f "$ALWAYS_ON_FILE" ]] && [[ "$(cat "$ALWAYS_ON_FILE")" == "1" ]]; }

ensure_running() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    return 0
  fi
  # Clean stale PID
  [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
  MONITOR="$DISPLAY_NAME" iio-hyprland "$DISPLAY_NAME" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
}

stop_if_running() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      for _ in 1 2 3; do
        kill -0 "$pid" 2>/dev/null && sleep 0.1 || break
      done
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
}

tablet_mode() {
  if is_always_on; then
    ensure_running
    notify "$ICON_TABLET" "Tablet mode" "Always-On: auto-rotate running."
    return 0
  fi

  if ! is_enabled; then
    notify "$ICON_TABLET" "Tablet mode" "Autorotate disabled."
    return 0
  fi

  ensure_running
  notify "$ICON_TABLET" "Tablet mode" "Starting auto-rotate on ${DISPLAY_NAME}."
}

laptop_mode() {
  if is_always_on; then
    # Ignore lid switch when Always-On is enabled
    ensure_running
    notify "$ICON_LAPTOP" "Laptop mode" "Always-On: ignoring lid switch."
    return 0
  fi

  stop_if_running
  notify "$ICON_LAPTOP" "Laptop mode" "Auto-rotate stopped."
}

case "${1-}" in
  tablet) tablet_mode; exit 0 ;;
  laptop) laptop_mode; exit 0 ;;
esac

# First-run defaults
mkdir -p "$HOME/.config/linuxflip"
[[ -f "$ENABLE_FILE"    ]] || echo "1" > "$ENABLE_FILE"
[[ -f "$ALWAYS_ON_FILE" ]] || echo "0" > "$ALWAYS_ON_FILE"

# Run linuxflip and point hooks back to this script
SELF="$(readlink -f "$0")"
linuxflip "$SELF tablet" "$SELF laptop"
