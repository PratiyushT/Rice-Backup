#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"
MASTER_FLAG="${MASTER_FLAG:-}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"
DEBUG=0
[[ "${1:-}" == "-d" ]] && DEBUG=1
log(){ [[ $DEBUG -eq 1 ]] && echo "[DEBUG] $*"; }

# Save original monitor config
ORIG_MONITOR_LINE="$(hyprctl -j monitors | jq -r \
  ".[] | select(.name==\"$MONITOR\") | \"\(.name),\(.width)x\(.height)@\(.refreshRate),\(.x)x\(.y),\(.scale)\"")"
log "Original monitor line: $ORIG_MONITOR_LINE"

start_rotation() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "Rotation already running"
    return
  fi
  log "Start rotation"
  iio-hyprland "$MONITOR" $MASTER_FLAG &
  echo $! > "$PID_FILE"
}

stop_rotation() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "Stop rotation"
    kill "$(cat "$PID_FILE")" || true
    rm -f "$PID_FILE"
  fi
  if [[ -n "$ORIG_MONITOR_LINE" ]]; then
    log "Restoring monitor: $ORIG_MONITOR_LINE"
    hyprctl keyword monitor "$ORIG_MONITOR_LINE,transform,0" >/dev/null 2>&1 || true
  fi
}

# Find tablet mode switch state file
TABLET_STATE_FILE=""
for dev in /sys/class/switch/*; do
  [[ -r "$dev/name" ]] || continue
  if grep -qi "tablet" "$dev/name"; then
    TABLET_STATE_FILE="$dev/state"
    break
  fi
done

if [[ -z "$TABLET_STATE_FILE" ]]; then
  echo "No tablet mode switch found in /sys/class/switch" >&2
  exit 1
fi
log "Using tablet switch: $TABLET_STATE_FILE"

# Monitor tablet mode changes
last_state=""
while true; do
  state="$(cat "$TABLET_STATE_FILE" 2>/dev/null || echo 0)"
  if [[ "$state" != "$last_state" ]]; then
    if [[ "$state" == "1" ]]; then
      log "Tablet mode ON → rotate on"
      start_rotation
    else
      log "Tablet mode OFF → rotate off"
      stop_rotation
    fi
    last_state="$state"
  fi
  sleep 0.25
done
