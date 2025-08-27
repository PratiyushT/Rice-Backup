#!/usr/bin/env bash
set -euo pipefail

# Default values (can be overridden by environment variables)
MONITOR="${MONITOR:-eDP-1}"           # example: MONITOR=eDP-1
MASTER_FLAG="${MASTER_FLAG:-}"        # example: MASTER_FLAG="--right-master"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"
DEBUG=0

# Parse args
if [[ "${1:-}" == "-d" ]]; then
    DEBUG=1
fi

log() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "[DEBUG] $*"
    fi
}

start_rotation() {
    log "Starting iio-hyprland for $MONITOR $MASTER_FLAG"
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log "iio-hyprland already running (PID $(cat "$PID_FILE"))"
        return
    fi
    iio-hyprland "$MONITOR" $MASTER_FLAG &
    echo $! > "$PID_FILE"
    log "Started with PID $(cat "$PID_FILE")"
}

stop_rotation() {
    log "Stopping iio-hyprland..."
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        kill "$(cat "$PID_FILE")" || true
        rm -f "$PID_FILE"
        log "Stopped iio-hyprland"
    fi
    # return display to normal orientation
    log "Resetting display transform for $MONITOR"
    hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,0" >/dev/null 2>&1 || true
}

log "Monitor: $MONITOR"
log "Master Flag: $MASTER_FLAG"
log "PID File: $PID_FILE"
log "Debug Mode: $DEBUG"

# If debug mode, show available sensors first
if [[ $DEBUG -eq 1 ]]; then
    echo "=== hyprctl monitors ==="
    hyprctl monitors
    echo
    echo "=== hyprctl devices ==="
    hyprctl devices
    echo
    echo "=== Available IIO Devices ==="
    ls -l /sys/bus/iio/devices || true
    echo
    echo "=== Tablet mode and orientation events ==="
fi

# Main loop: watch tablet mode changes
monitor-sensor | while read -r line; do
    log "Event: $line"
    case "$line" in
        *"Tablet mode: on"*)
            start_rotation
            ;;
        *"Tablet mode: off"*)
            stop_rotation
            ;;
    esac
done
