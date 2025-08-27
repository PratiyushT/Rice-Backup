#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
STATE_FILE="${STATE_FILE:-$HOME/.config/linuxflip/state}"          # tablet=1|0, laptop=1|0
MODE_FILE="${MODE_FILE:-$HOME/.config/linuxflip/current_mode}"     # "tablet" or "laptop"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"
MENU_XML="${MENU_XML:-$HOME/.local/share/waybar/menus/autorotate.xml}"

# Icons for notifications
ICON_TABLET="${ICON_TABLET:-/Wallbash-Icon/media/knob-75.svg}"
ICON_LAPTOP="${ICON_LAPTOP:-/Wallbash-Icon/media/knob-25.svg}"

# ===== State helpers =====
ensure_state() {
  mkdir -p "$(dirname "$STATE_FILE")"
  if [[ ! -f "$STATE_FILE" ]]; then
    printf "tablet=1\nlaptop=0\n" > "$STATE_FILE"   # default: tablet enabled, laptop disabled
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
  # If our tracked process is alive, done
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null || echo)" 2>/dev/null; then
    return 0
  fi

  # If any user-owned iio-hyprland already running for this display, adopt it (no duplicate)
  mapfile -t current < <(pgrep -u "$USER" -fa iio-hyprland | awk -v mon="$DISPLAY_NAME" '
    $0 ~ ("\\<"mon"\\>") {print $1}
  ')
  if [[ "${#current[@]}" -gt 0 ]]; then
    echo "${current[0]}" > "$PID_FILE"
    return 0
  fi

  # Otherwise launch a fresh one
  MONITOR="$DISPLAY_NAME" iio-hyprland "$DISPLAY_NAME" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
}

stop_if_running() {
  # Stop the instance we launched (PID file)
  if [[ -f "$PID_FILE" ]]; then
    local pid; pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      for _ in 1 2 3; do
        kill -0 "$pid" 2>/dev/null && sleep 0.1 || break
      done
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi

  # Hardened cleanup: kill any other user-owned iio-hyprland for this display
  # Skip if PID_SCOPE=strict is set in env
  if [[ "${PID_SCOPE:-}" != "strict" ]]; then
    # Match either "... iio-hyprland eDP-1" or 'MONITOR=eDP-1 iio-hyprland ...'
    mapfile -t extras < <(pgrep -u "$USER" -fa iio-hyprland | awk -v mon="$DISPLAY_NAME" '
      $0 ~ ("\\<"mon"\\>") {print $1}
    ')
    for epid in "${extras[@]:-}"; do
      [[ -n "$epid" ]] || continue
      # Don’t re-kill the same PID we already handled
      if [[ -z "${pid:-}" || "$epid" != "$pid" ]]; then
        kill "$epid" 2>/dev/null || true
        sleep 0.1
        kill -0 "$epid" 2>/dev/null && kill -9 "$epid" 2>/dev/null || true
      fi
    done
  fi
}

reload_waybar_quiet() { pkill -SIGUSR2 waybar 2>/dev/null || true; }

# ===== Menu writer (called on every toggle) =====
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
  echo "tablet" > "$MODE_FILE"
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
  echo "laptop" > "$MODE_FILE"
  read_state
  if [[ "$laptop" == "1" ]]; then
    ensure_running
    notify "$ICON_LAPTOP" "Laptop mode" "Autorotate running."
  else
    stop_if_running
    notify "$ICON_LAPTOP" "Laptop mode" "Autorotate disabled."
  fi
}

# ===== Immediate-apply helper =====
apply_now_if_current_mode() {
  local want="$1"   # "tablet" | "laptop"
  local cur=""
  [[ -r "$MODE_FILE" ]] && cur="$(cat "$MODE_FILE" 2>/dev/null || true)"
  if [[ -z "$cur" ]] && command -v linuxflip >/dev/null 2>&1; then
    if linuxflip --print-mode 2>/dev/null | grep -qi tablet; then cur="tablet"; fi
    if linuxflip --print-mode 2>/dev/null | grep -qi laptop; then cur="laptop"; fi
  fi
  [[ "$cur" == "$want" ]]
}

# ===== Toggles =====
toggle_tablet() {
  read_state
  if [[ "$tablet" == "1" ]]; then
    tablet=0
    if apply_now_if_current_mode "tablet"; then stop_if_running; fi
  else
    tablet=1
    if apply_now_if_current_mode "tablet"; then ensure_running; fi
  fi
  write_state
  write_menu_xml
  reload_waybar_quiet
}

toggle_laptop() {
  read_state
  if [[ "$laptop" == "1" ]]; then
    laptop=0
    if apply_now_if_current_mode "laptop"; then stop_if_running; fi
  else
    laptop=1
    if apply_now_if_current_mode "laptop"; then ensure_running; fi
  fi
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
  run|"")          mkdir -p "$(dirname "$MODE_FILE")" ; ensure_state ; write_menu_xml ; exec linuxflip "$SELF tablet" "$SELF laptop" ;;
  *) echo "Usage: $SELF [run|tablet|laptop|toggle-tablet|toggle-laptop|write-menu]" >&2 ; exit 2 ;;
esac

