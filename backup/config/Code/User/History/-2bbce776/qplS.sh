#!/usr/bin/env bash
set -euo pipefail

# Config
DISPLAY_NAME="${DISPLAY_NAME:-eDP-1}"                   # change if your internal display is different
PID_FILE="${PID_FILE:-/tmp/iio-hyprland.${USER}.pid}"   # where we store the child PID

# --- Hooks ---
tablet_mode() {
  # If already running, do nothing
  if [[ -f "$PID_FILE" ]]; then
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "[info] iio-hyprland already running with PID $(cat "$PID_FILE")"
      return 0
    else
      echo "[warn] Stale PID file found. Cleaning."
      rm -f "$PID_FILE"
    fi
  fi

  echo "[hook] Entered tablet mode. Starting auto-rotate on ${DISPLAY_NAME}"
  MONITOR="$DISPLAY_NAME" iio-hyprland "$DISPLAY_NAME" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
}

laptop_mode() {
  echo "[hook] Returned to laptop mode. Stopping auto-rotate if running."
  if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE")"
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID" 2>/dev/null || true
      # Give it a brief moment to exit, then hard kill if needed
      for _ in 1 2 3; do
        if kill -0 "$PID" 2>/dev/null; then sleep 0.1; else break; fi
      done
      if kill -0 "$PID" 2>/dev/null; then kill -9 "$PID" 2>/dev/null || true; fi
    fi
    rm -f "$PID_FILE"
  else
    echo "[info] No PID file. Nothing to stop."
  fi
}

# --- Entrypoints ---
# If called with `tablet` or `laptop`, act as a hook target.
case "${1-}" in
  tablet) tablet_mode; exit 0 ;;
  laptop) laptop_mode; exit 0 ;;
esac

# If called with no args, run linuxflip and point both hooks back to this script.
# This keeps everything in one file.
SELF="$(readlink -f "$0")"
echo "[info] Launching linuxflip. Tablet -> start, Laptop -> stop."
linuxflip "$SELF tablet" "$SELF laptop"
