#!/usr/bin/env bash
set -euo pipefail

# Config
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"                     # internal panel name
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"     # child PID storage
APP_NAME="${APP_NAME:-linuxflip-autorotate}"              # notification app name

# Icons (set your own absolute paths if you want)
# If these files do not exist, we fall back to themed icons.
ICON_TABLET_DEFAULT="/Wallbash-Icon/media/knob-75.svg"
ICON_LAPTOP_DEFAULT="/Wallbash-Icon/media/knob-25.svg"
ICON_TABLET="${ICON_TABLET:-$ICON_TABLET_DEFAULT}"
ICON_LAPTOP="${ICON_LAPTOP:-$ICON_LAPTOP_DEFAULT}"

# Resolve an icon to pass to notify-send (file path or themed name)
resolve_icon() {
  local candidate="$1" fallback="$2"
  if [[ -n "${candidate}" && -r "${candidate}" ]]; then
    printf "%s" "${candidate}"
  elif command -v lookit-icon >/dev/null 2>&1; then
    # optional helper if you have one; ignored if missing
    lookit-icon "${fallback}" || printf "%s" "${fallback}"
  else
    printf "%s" "${fallback}"
  fi
}

ICON_TABLET_RESOLVED="$(resolve_icon "${ICON_TABLET}" "rotation-allowed")"
ICON_LAPTOP_RESOLVED="$(resolve_icon "${ICON_LAPTOP}" "computer-laptop")"

notify() {
  # Safe notification wrapper
  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      --app-name="${APP_NAME}" \
      --icon="$1" \
      --hint=string:x-canonical-private-synchronous:"${APP_NAME}-status" \
      "$2" "$3"
  else
    printf "[notify-missing] %s - %s\n" "$2" "$3" >&2
  fi
}

# --- Hooks ---
tablet_mode() {
  # Already running
  if [[ -f "$PID_FILE" ]]; then
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      notify "${ICON_TABLET_RESOLVED}" "Tablet mode" "Auto-rotate already running."
      return 0
    else
      rm -f "$PID_FILE"
    fi
  fi

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
        if kill -0 "$PID" 2>/dev/null; then sleep 0.1; else break; fi
      done
      if kill -0 "$PID" 2>/dev/null; then kill -9 "$PID" 2>/dev/null || true; fi
    fi
    rm -f "$PID_FILE"
    notify "${ICON_LAPTOP_RESOLVED}" "Laptop mode" "Auto-rotate stopped."
  else
    notify "${ICON_LAPTOP_RESOLVED}" "Laptop mode" "Nothing to stop."
  fi
}

# --- Entrypoints ---
case "${1-}" in
  tablet) tablet_mode; exit 0 ;;
  laptop) laptop_mode; exit 0 ;;
esac

SELF="$(readlink -f "$0")"
linuxflip "$SELF tablet" "$SELF laptop"
