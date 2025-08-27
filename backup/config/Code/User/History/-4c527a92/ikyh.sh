#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"
MASTER_FLAG="${MASTER_FLAG:-}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"
DEBUG=0
[[ "${1:-}" == "-d" ]] && DEBUG=1
log(){ [[ $DEBUG -eq 1 ]] && echo "[DEBUG] $*"; }

# Capture original monitor settings to restore later
ORIG_MONITOR_LINE="$(hyprctl -j monitors | jq -r \
  ".[] | select(.name==\"$MONITOR\") | \"\(.name),\(.width)x\(.height)@\(.refreshRate),\(.x)x\(.y),\(.scale)\"")"
log "Original monitor line: ${ORIG_MONITOR_LINE:-<none>}"

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
  if [[ -n "${ORIG_MONITOR_LINE:-}" ]]; then
    log "Restoring monitor: $ORIG_MONITOR_LINE"
    hyprctl keyword monitor "$ORIG_MONITOR_LINE,transform,0" >/dev/null 2>&1 || true
  fi
}

# Find the event node for the Lenovo Yoga Tablet Mode Control switch
find_tablet_event() {
  local n path
  for path in /sys/class/input/event*/device/name; do
    [[ -r "$path" ]] || continue
    n="$(cat "$path")"
    if echo "$n" | grep -qi "tablet.*mode.*control"; then
      echo "/dev/input/$(basename "$(dirname "$path")")"
      return 0
    fi
  done
  return 1
}

DEV=""
if DEV="$(find_tablet_event)"; then
  log "Using tablet-mode event device: $DEV"
else
  echo "Could not locate the tablet-mode input device. Abort." >&2
  exit 1
fi

# Prefer libinput for reading SW_TABLET_MODE. Fallback to evtest if needed.
reader=""
if command -v libinput >/dev/null 2>&1; then
  reader="libinput"
elif command -v evtest >/dev/null 2>&1; then
  reader="evtest"
else
  echo "Need libinput or evtest installed to read switch events." >&2
  exit 1
fi
log "Event reader: $reader"

# Helper to emit current state once at startup using evtest if available
query_state_once() {
  if command -v evtest >/dev/null 2>&1; then
    evtest --query "$DEV" EV_SW SW_TABLET_MODE && echo on || echo off
  else
    # If evtest is not present, return unknown and let the stream set state
    echo unknown
  fi
}

# Track state and react
state="unknown"
initial="$(query_state_once)"
if [[ "$initial" == "on" ]]; then
  state="on"
  log "Initial state: ON → rotate on"
  start_rotation
elif [[ "$initial" == "off" ]]; then
  state="off"
  log "Initial state: OFF"
fi

cas
