#!/usr/bin/env bash
set -euo pipefail

# Config
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"

# Enable flag file
ENABLE_FILE="${ENABLE_FILE:-$HOME/.config/linuxflip/autorotate.enabled}"

# Icons
ICON_TABLET_DEFAULT="/Wallbash-Icon/media/knob-75.svg"
ICON_LAPTOP_DEFAULT="/Wallbash-Icon/media/knob-25.svg"
ICON_TABLET="${ICON_TABLET:-$ICON_TABLET_DEFAULT}"
ICON_LAPTOP="${ICON_LAPTOP:-$ICON_LAPTOP_DEFAULT}"

resolve_icon() {
  local candidate="$1" fallback="$2"
  if [[ -n "${candidate}" && -r "${candidate}" ]]; then
    printf "%s" "${candidate}"
  else
    printf "%s" "${fallback}"
  fi
}

ICON_TABLET_RESOLVED="$(resolve_icon "${ICON_TABLET}" "rotation-allowed")"
ICON_LAPTOP_RESOLVED="$(resolve_icon "${ICON_LAPTOP}" "computer-laptop")"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      --app-name="${APP_NAME}" \
      --icon="$1" \
      --hint=string:x-canonical-private-synchronous:"${APP_NAME}-status" \
      "$2" "$3"
  fi
}

is_enabled() {
  [[ -f "$ENABLE_FILE" ]] && [[ "$(cat "$ENABLE_FILE")" == "1" ]]
}

tablet_mode() {
  # Respect enable flag
  if ! is_enabled; then
    notify "${ICON_TABLET_RESOLVED}" "Tablet mode" "Autorotate disabled."
    return 0
  fi

  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    notify "${ICON_TABLET_RESOLVED}" "Tablet mode" "Auto-rotate already running."
    return 0
  fi

  # Clean stale pid if any
  [[ -f "$PID_FILE" ]] && ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null && rm -f "$PID_FILE"

  notify "${ICON_TABLET_RESOLVED}" "Tablet mode" "Starting auto-rotate on ${DISPLAY_NAME}."
  MONITOR="$DISPLAY_NAME" iio-hyprland "$DISPLAY_NAME" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
}

laptop_mode() {
  if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE")"
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID" 2>/dev/null || true
      for _ in 1 2 3; do
        kill -0 "$PID" 2>/dev/null && sleep 0.1 || break
      done
      kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
    notify "${ICON_LAPTOP_RESOLVED}" "Laptop mode" "Auto-rotate stopped."
  else
    notify "${ICON_LAPTOP_RESOLVED}" "Laptop mode" "Nothing to stop."
  fi
}

case "${1-}" in
  tablet) tablet_mode; exit 0 ;;
  laptop) laptop_mode; exit 0 ;;
esac

# Ensure the enable flag exists (default enabled = 1)
mkdir -p "$HOME/.config/linuxflip"
[[ -f "$ENABLE_FILE" ]] || echo "1" > "$ENABLE_FILE"

SELF="$(readlink -f "$0")"
# No launch notification per your request
linuxflip "$SELF tablet" "$SELF laptop"
