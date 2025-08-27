#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
STATE_FILE="${STATE_FILE:-$HOME/.config/linuxflip/state}"      # tablet=1|0  laptop=1|0
APP_NAME="${APP_NAME:-linuxflip-autorotate}"
MENU_XML="${MENU_XML:-$HOME/.local/share/waybar/menus/autorotate.xml}"

# Icons for notifications
ICON_TABLET="${ICON_TABLET:-/Wallbash-Icon/media/knob-75.svg}"
ICON_LAPTOP="${ICON_LAPTOP:-/Wallbash-Icon/media/knob-25.svg}"

# ===== State helpers =====
ensure_state() {
  mkdir -p "$(dirname "$STATE_FILE")"
  if [[ ! -f "$STATE_FILE" ]]; then
    # Default: tablet only enabled, laptop disabled
    printf "tablet=1\nlaptop=0\n" > "$STATE_FILE"
  fi
}
read_state() {
  ensure_state
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  tablet="${tablet:-1}"
  laptop="${laptop:-0}"
}
write_state() {
  printf "tablet=%s\nlaptop=%s\n" "${tablet}" "${laptop}" > "$STATE_FILE"
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

reload_waybar_quiet() {
  pkill -SIGUSR2 waybar 2>/dev/null || true
}

# ===== Menu writer (static file updated by this script) =====
write_menu_xml() {
  read_state
  local label_tab="Tablet Mode: "; local label_lap="Laptop Mode: "
  if [[ "$tablet" == "1" ]]; then label_tab+="Enabled"; else label_tab+="Disabled"; fi
  if [[ "$laptop" == "1" ]]; then label_lap+="Enabled"; else label_lap+="Disabled"; fi

  mkdir -p "$(dirname "$MENU_XML")"
  cat > "$MENU_XML" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<interface>
  <object class="GtkMenu" id="menu">
    <child>
      <object class="GtkMenuItem" id="toggle-tablet">
        <property name="label">${label_tab}</property>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="toggle-laptop">
        <property name="label">${label_lap}</property>
      </object>
    </child>
  </object>
</interface>
EOF
}

# ===== Mode handlers =====
tablet_mode() {
  read_state
  if [[ "$tablet" == "1" ]]; then
    ensure_running
    notify "$ICON_TABLET" "Tablet mode" "Autorotate running."
  else
    stop_if_running
    notify "$ICON_TABLET" "Tablet mode" "Autorotate disabled."
  fi
}

laptop_mode() {
  read_state
  if [[ "$laptop" == "1" ]]; then
    ensure_running
    notify "$ICON_LAPTOP" "Laptop mode" "Autorotate running."
  else
    stop_if_running
    notify "$ICON_LAPTOP" "Laptop mode" "Autorotate disabled."
  fi
}

# ===== Toggles =====
toggle_tablet() {
  read_state
  if [[ "$tablet" == "1" ]]; then tablet=0; else tablet=1; end
  write_state
  write_menu_xml
  reload_waybar_quiet
}

toggle_laptop() {
  read_state
  if [[ "$laptop" == "1" ]]; then laptop=0; else laptop=1; end
  write_state
  write_menu_xml
  reload_waybar_quiet
}

# ===== Entrypoint =====
SELF="$(readlink -f "$0")"
case "${1-}" in
  tablet)          tablet_mode ;;
  laptop)          laptop_mode ;;
  toggle-tablet)   toggle_tablet ;;
  toggle-laptop)   toggle_laptop ;;
  write-menu)      write_menu_xml ; reload_waybar_quiet ;;
  run|"")          ensure_state ; write_menu_xml ; exec linuxflip "$SELF tablet" "$SELF laptop" ;;
  *) echo "Usage: $SELF [run|tablet|laptop|toggle-tablet|toggle-laptop|write-menu]" >&2 ; exit 2 ;;
esac
