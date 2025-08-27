#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"
ENABLE_FILE="${ENABLE_FILE:-$HOME/.config/linuxflip/autorotate.enabled}"
SPEC_FILE="${SPEC_FILE:-$HOME/.config/linuxflip/${DISPLAY_NAME}.spec}"

# Icons used only for notifications on mode changes
ICON_TABLET_DEFAULT="/Wallbash-Icon/media/knob-75.svg"
ICON_LAPTOP_DEFAULT="/Wallbash-Icon/media/knob-25.svg"

# ===== Utilities =====
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    # No launch notification anywhere else in the script
    notify-send --app-name="${APP_NAME}" --icon="$1" \
      --hint=string:x-canonical-private-synchronous:"${APP_NAME}-status" \
      "$2" "$3"
  fi
}

# Capture the current eDP-1 spec so we can restore it later
capture_spec() {
  local info block w h rr x y scale
  info="$(hyprctl monitors 2>/dev/null || true)"

  # Extract the block for DISPLAY_NAME
  block="$(printf '%s\n' "$info" | awk -v m="$DISPLAY_NAME" '
    /^Monitor / && $2 ~ m {p=1}
    p{print}
    /^Monitor / && $2 !~ m && p{exit}
  ')"

  w="$(printf '%s\n' "$block" | sed -n 's/.*width:[[:space:]]*\([0-9]\+\).*/\1/p'   | head -1)"
  h="$(printf '%s\n' "$block" | sed -n 's/.*height:[[:space:]]*\([0-9]\+\).*/\1/p' | head -1)"
  rr="$(printf '%s\n' "$block" | sed -n 's/.*refreshRate:[[:space:]]*\([0-9.]\+\).*/\1/p' | head -1)"
  x="$(printf '%s\n' "$block" | sed -n 's/.*x:[[:space:]]*\([-0-9]\+\).*/\1/p'     | head -1)"
  y="$(printf '%s\n' "$block" | sed -n 's/.*y:[[:space:]]*\([-0-9]\+\).*/\1/p'     | head -1)"
  scale="$(printf '%s\n' "$block" | sed -n 's/.*scale:[[:space:]]*\([0-9.]\+\).*/\1/p' | head -1)"

  if [[ -n "${w:-}" && -n "${h:-}" && -n "${rr:-}" && -n "${x:-}" && -n "${y:-}" && -n "${scale:-}" ]]; then
    mkdir -p "$(dirname "$SPEC_FILE")"
    printf '%s,%sx%s@%s,%sx%s,%s\n' "$DISPLAY_NAME" "$w" "$h" "$rr" "$x" "$y" "$scale" >"$SPEC_FILE"
  fi
}

# Restore the previously captured spec for eDP-1 only
restore_spec() {
  if [[ -r "$SPEC_FILE" ]]; then
    hyprctl keyword monitor "$(cat "$SPEC_FILE")" >/dev/null 2>&1 || true
  fi
  # Ensure orientation is normal for eDP-1 only
  if command -v wlr-randr >/dev/null 2>&1; then
    wlr-randr --output "$DISPLAY_NAME" --transform normal >/dev/null 2>&1 || true
  fi
}

is_enabled() {
  [[ -f "$ENABLE_FILE" ]] && [[ "$(cat "$ENABLE_FILE")" == "1" ]]
}

# ===== Hooks called by linuxflip =====
tablet_mode() {
  if ! is_enabled; then
    restore_spec
    notify "${ICON_TABLET_DEFAULT}" "Tablet mode" "Autorotate disabled. eDP-1 restored."
    return 0
  fi

  # Already running
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    notify "${ICON_TABLET_DEFAULT}" "Tablet mode" "Auto-rotate already running."
    return 0
  fi

  # Clean stale PID if any
  [[ -f "$PID_FILE" ]] && ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null && rm -f "$PID_FILE"

  notify "${ICON_TABLET_DEFAULT}" "Tablet mode" "Starting auto-rotate on ${DISPLAY_NAME}."
  MONITOR="$DISPLAY_NAME" iio-hyprland "$DISPLAY_NAME" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
}

laptop_mode() {
  # Always stop autorotate
  if [[ -f "$PID_FILE" ]]; then
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

  # Restore saved laptop spec for eDP-1 only
  restore_spec
  notify "${ICON_LAPTOP_DEFAULT}" "Laptop mode" "Auto-rotate stopped. eDP-1 restored."
}

# ===== Entrypoints =====
case "${1-}" in
  tablet) tablet_mode; exit 0 ;;
  laptop) laptop_mode; exit 0 ;;
esac

# First-run setup
mkdir -p "$HOME/.config/linuxflip"
[[ -f "$ENABLE_FILE" ]] || echo "1" > "$ENABLE_FILE"
[[ -f "$SPEC_FILE"  ]] || capture_spec

# Run linuxflip and point its hooks back to this file
SELF="$(readlink -f "$0")"
linuxflip "$SELF tablet" "$SELF laptop"
