#!/usr/bin/env bash
set -euo pipefail

ENABLE_FILE="${ENABLE_FILE:-$HOME/.config/linuxflip/autorotate.enabled}"
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"
APP_NAME="${APP_NAME:-linuxflip-autorotate}"
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"
SPEC_FILE="${SPEC_FILE:-$HOME/.config/linuxflip/${DISPLAY_NAME}.spec}"
WATCHER="${WATCHER:-$HOME/.local/lib/hyde/linuxflip_auto_rotate.sh}"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="${APP_NAME}" "$1" "$2"
  fi
}

capture_spec() {
  local info block w h rr x y scale
  info="$(hyprctl monitors 2>/dev/null || true)"
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

mkdir -p "$(dirname "$ENABLE_FILE")"
[[ -f "$ENABLE_FILE" ]] || echo "1" > "$ENABLE_FILE"

state="$(cat "$ENABLE_FILE" || echo 1)"

# Always capture current eDP-1 spec right before toggling
capture_spec

if [[ "$state" == "1" ]]; then
  # Disable
  echo "0" > "$ENABLE_FILE"
  # Immediately act like laptop mode: stop rotation and restore eDP-1
  if [[ -x "$WATCHER" ]]; then
    "$WATCHER" laptop
  else
    # Fallback if WATCHER path changed: best-effort stop and restore
    if [[ -f "$PID_FILE" ]]; then
      pid="$(cat "$PID_FILE")"
      kill "$pid" 2>/dev/null || true
      rm -f "$PID_FILE"
    fi
    # Use the watcher’s restore rules if present
    hyprctl keyword monitor "$(cat "$SPEC_FILE")" >/dev/null 2>&1 || true
    command -v wlr-randr >/dev/null 2>&1 && wlr-randr --output "$DISPLAY_NAME" --transform normal >/dev/null 2>&1 || true
  fi
  notify "Autorotate" "Disabled. Laptop mode enforced."
else
  # Enable
  echo "1" > "$ENABLE_FILE"
  notify "Autorotate" "Enabled"
fi
