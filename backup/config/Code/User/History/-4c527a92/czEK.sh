#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"           # set with: MONITOR=eDP-1
MASTER_FLAG="${MASTER_FLAG:-}"        # set with: MASTER_FLAG="--right-master" or "--left-master"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"

start_rotation() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    return
  fi
  iio-hyprland "$MONITOR" $MASTER_FLAG &
  echo $! > "$PID_FILE"
}

stop_rotation() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    kill "$(cat "$PID_FILE")" || true
    rm -f "$PID_FILE"
  fi
  # return display to normal orientation
  hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,0" >/dev/null 2>&1 || true
}

monitor-sensor | while read -r line; do
  case "$line" in
    *"Tablet mode: on"*)
      start_rotation
      ;;
    *"Tablet mode: off"*)
      stop_rotation
      ;;
  esac
done
