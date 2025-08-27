#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
STATE_FILE="${STATE_FILE:-$HOME/.config/linuxflip/state}"   # enabled=1|0, always_on=1|0
APP_NAME="${APP_NAME:-linuxflip-autorotate}"

# Icons for notifications on mode changes
ICON_TABLET="${ICON_TABLET:-/Wallbash-Icon/media/knob-75.svg}"
ICON_LAPTOP="${ICON_LAPTOP:-/Wallbash-Icon/media/knob-25.svg}"

# ===== State helpers =====
ensure_state() {
  mkdir -p "$(dirname "$STATE_FILE")"
  if [[ ! -f "$STATE_FILE" ]]; then
    printf "enabled=1\nalways_on=0\n" > "$STATE_FILE"
  fi
}
read_state() {
  ensure_state
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  enabled="${enabled:-1}"
  always_on="${always_on:-0}"
}
write_state() {
  printf "enabled=%s\nalways_on=%s\n" "${enabled}" "${always_on}" > "$STATE_FILE"
}

# ===== Utilities =====
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="${APP_NAME}" --icon="$1" \
      --hint=string:x-canonical-private-synchronous:"${APP_NAME}-status" \
      "$2" "$3"
  fi
}

ensure_running() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    return 0
  fi
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

# ===== Mode handlers with precedence =====
# If enabled=0          => stop in both modes
# If enabled=1, always_on=1 => run in both modes
# If enabled=1, always_on=0 => run only in tablet mode
tablet_mode() {
  read_state
  if [[ "$enabled" != "1" ]]; then
    stop_if_running
    notify "$ICON_TABLET" "Tablet mode" "Autorotate is disabled."
    return 0
  fi
  if [[ "$always_on" == "1" ]]; then
    ensure_running
    notify "$ICON_TABLET" "Tablet mode" "Always-On: auto-rotate running."
    return 0
  fi
  ensure_running
  notify "$ICON_TABLET" "Tablet mode" "Starting auto-rotate on ${DISPLAY_NAME}."
}

laptop_mode() {
  read_state
  if [[ "$enabled" != "1" ]]; then
    stop_if_running
    notify "$ICON_LAPTOP" "Laptop mode" "Autorotate is disabled."
    return 0
  fi
  if [[ "$always_on" == "1" ]]; then
    ensure_running
    notify "$ICON_LAPTOP" "Laptop mode" "Always-On: running in laptop mode."
    return 0
  fi
  stop_if_running
  notify "$ICON_LAPTOP" "Laptop mode" "Auto-rotate stopped (tablet-only)."
}

# ===== Explicit setters for manual menu =====
# Set tablet-only behavior (enabled=1, always_on=0)
set_tablet_only() {
  read_state
  enabled=1
  always_on=0
  write_state
  # Safe immediate effect: stop rotation now (it will start on next tablet event)
  stop_if_running
  notify "dialog-information" "Autorotate" "Enabled (tablet mode only)."
}

# Disable autorotate everywhere (enabled=0)
disable_all() {
  read_state
  enabled=0
  write_state
  stop_if_running
  notify "dialog-information" "Autorotate" "Disabled (both modes)."
}

# Optional: manual toggles if you still want them
toggle_always() {
  read_state
  if [[ "$always_on" == "1" ]]; then
    always_on=0
    write_state
    # If we are in laptop and tablet-only policy applies, stop now
    stop_if_running
    notify "dialog-information" "Autorotate" "Always-On disabled"
  else
    always_on=1
    write_state
    if [[ "$enabled" == "1" ]]; then
      ensure_running
    fi
    notify "dialog-information" "Autorotate" "Always-On enabled"
  fi
}

# ===== Entrypoint =====
SELF="$(readlink -f "$0")"
case "${1-}" in
  tablet)           tablet_mode ;;
  laptop)           laptop_mode ;;
  set-tablet-only)  set_tablet_only ;;
  disable-all)      disable_all ;;
  toggle-always)    toggle_always ;;   # optional to keep
  run|"")           ensure_state ; exec linuxflip "$SELF tablet" "$SELF laptop" ;;
  *)  echo "Usage: $SELF [run|tablet|laptop|set-tablet-only|disable-all|toggle-always]" >&2 ; exit 2 ;;
esac
