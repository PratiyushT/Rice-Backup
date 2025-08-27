#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
STATE_FILE="${STATE_FILE:-$HOME/.config/linuxflip/state}"   # key=value pairs
APP_NAME="${APP_NAME:-linuxflip-autorotate}"

# Icons for notifications
ICON_TABLET="/Wallbash-Icon/media/knob-75.svg"
ICON_LAPTOP="/Wallbash-Icon/media/knob-25.svg"

# ===== State helpers (enabled, always_on) =====
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

running_flag() {
  if [[ -f "$PID_FILE" ]]; then
    local pid; pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    kill -0 "${pid:-0}" 2>/dev/null && echo 1 && return
  fi
  echo 0
}

# ===== Hooks consumed by linuxflip =====
tablet_mode() {
  read_state
  if [[ "$always_on" == "1" ]]; then
    ensure_running
    notify "$ICON_TABLET" "Tablet mode" "Always-On: auto-rotate running."
    return 0
  fi
  if [[ "$enabled" != "1" ]]; then
    notify "$ICON_TABLET" "Tablet mode" "Autorotate disabled."
    return 0
  fi
  ensure_running
  notify "$ICON_TABLET" "Tablet mode" "Starting auto-rotate on ${DISPLAY_NAME}."
}

laptop_mode() {
  read_state
  if [[ "$always_on" == "1" ]]; then
    ensure_running
    notify "$ICON_LAPTOP" "Laptop mode" "Always-On: ignoring lid switch."
    return 0
  fi
  stop_if_running
  notify "$ICON_LAPTOP" "Laptop mode" "Auto-rotate stopped."
}

# ===== Waybar endpoints =====
status_json() {
  read_state
  local running; running="$(running_flag)"

  # Text/icon
  local text=""
  # Tooltip
  local tooltip="Autorotate: "
  if [[ "$enabled" == "1" ]]; then tooltip+="Enabled"; else tooltip+="Disabled"; fi
  tooltip+="\nAlways-On: "
  if [[ "$always_on" == "1" ]]; then tooltip+="On"; else tooltip+="Off"; fi
  tooltip+="\nProcess: "
  if [[ "$running" == "1" ]]; then tooltip+="Running"; else tooltip+="Stopped"; fi

  # Classes
  local classes=()
  if [[ "$enabled" == "1" ]]; then classes+=("enabled"); else classes+=("disabled"); fi
  if [[ "$always_on" == "1" ]]; then classes+=("always_on"); else classes+=("not_always_on"); fi
  if [[ "$running" == "1" ]]; then classes+=("running"); else classes+=("stopped"); fi

  printf '{ "text": "%s", "alt": "autorotate", "tooltip": "%s", "class": [%s] }\n' \
    "$text" "$tooltip" \
    "$(printf '"%s",' "${classes[@]}" | sed 's/,$//')"
}

toggle_enable() {
  read_state
  if [[ "$enabled" == "1" ]]; then
    enabled=0
    write_state
    # behave like laptop immediately
    "$SELF" laptop >/dev/null 2>&1 || true
    notify "dialog-information" "Autorotate" "Disabled"
  else
    enabled=1
    write_state
    notify "dialog-information" "Autorotate" "Enabled"
  fi
}

toggle_always() {
  read_state
  if [[ "$always_on" == "1" ]]; then
    always_on=0
    write_state
    # Stop if we are effectively in laptop behavior
    "$SELF" laptop >/dev/null 2>&1 || true
    notify "dialog-information" "Autorotate" "Always-On disabled"
  else
    always_on=1
    write_state
    # Start now
    "$SELF" tablet >/dev/null 2>&1 || true
    notify "dialog-information" "Autorotate" "Always-On enabled"
  fi
}

# ===== Entrypoint =====
SELF="$(readlink -f "$0")"
case "${1-}" in
  tablet)        tablet_mode ;;
  laptop)        laptop_mode ;;
  status)        status_json ;;
  toggle-enable) toggle_enable ;;
  toggle-always) toggle_always ;;
  run|"")        ensure_state; exec linuxflip "$SELF tablet" "$SELF laptop" ;;
  *)             echo "Usage: $SELF [run|tablet|laptop|status|toggle-enable|toggle-always]" >&2; exit 2 ;;
esac
