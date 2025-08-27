#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"           # change if your internal panel has a different name
MASTER_FLAG="${MASTER_FLAG:-}"        # e.g. --right-master or --left-master
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"
SAVE_FILE="$RUNTIME_DIR/hypr-orig-monitor.txt"

case "${1:-}" in
  on)
    # Save current monitor config only once
    if [[ ! -s "$SAVE_FILE" ]]; then
      hyprctl -j monitors | jq -r \
        ".[] | select(.name==\"$MONITOR\") | \"\(.name),\(.width)x\(.height)@\(.refreshRate),\(.x)x\(.y),\(.scale)\"" > "$SAVE_FILE" || true
    fi
    # Start iio-hyprland if not running
    if [[ ! -f "$PID_FILE" ]] || ! kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
      iio-hyprland "$MONITOR" $MASTER_FLAG &
      echo $! > "$PID_FILE"
    fi
    ;;
  off)
    # Stop iio-hyprland if running
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
      kill "$(cat "$PID_FILE")" || true
      rm -f "$PID_FILE"
    fi
    # Restore original monitor config
    if [[ -s "$SAVE_FILE" ]]; then
      ORIG="$(cat "$SAVE_FILE")"
      hyprctl keyword monitor "$ORIG,transform,0" >/dev/null 2>&1 || true
    fi
    ;;
  *)
    echo "Usage: tablet-rotate {on|off}" >&2
    exit 1
    ;;
esac
