#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"
MASTER_FLAG="${MASTER_FLAG:-}"   # e.g. --right-master or --left-master
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"

# Hinge thresholds (degrees)
HINGE_ON="${HINGE_ON:-240}"   # start rotation if >= this angle
HINGE_OFF="${HINGE_OFF:-210}" # stop rotation if <= this angle

DEBUG=0
[[ "${1:-}" == "-d" ]] && DEBUG=1

log() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "[DEBUG] $*"
    fi
}

# Capture the monitor's original settings so we can restore them later
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
        log "Restoring monitor to: $ORIG_MONITOR_LINE"
        hyprctl keyword monitor "$ORIG_MONITOR_LINE,transform,0" >/dev/null 2>&1 || true
    fi
}

find_hinge_file() {
    local f
    for f in /sys/bus/iio/devices/iio:device*/in_hinge_angle_input \
             /sys/bus/iio/devices/iio:device*/in_hinge_*_input \
             /sys/bus/iio/devices/iio:device*/in_*_hinge*_input; do
        [[ -r "$f" ]] && { echo "$f"; return 0; }
    done
    return 1
}

HINGE_FILE=""
if HINGE_FILE="$(find_hinge_file)"; then
    MODE="hinge"
    log "Using hinge file: $HINGE_FILE"
else
    MODE="orientation"
    log "No hinge file found, using orientation mode"
fi

folded=0

if [[ "$MODE" == "hinge" ]]; then
    while true; do
        if ANGLE="$(cat "$HINGE_FILE" 2>/dev/null)"; then
            if (( DEBUG )); then
                echo "[DEBUG] Hinge angle: $ANGLE"
            fi
            if (( folded == 0 )) && (( ANGLE >= HINGE_ON )); then
                folded=1
                log "Angle >= $HINGE_ON → rotate on"
                start_rotation
            elif (( folded == 1 )) && (( ANGLE <= HINGE_OFF )); then
                folded=0
                log "Angle <= $HINGE_OFF → rotate off"
                stop_rotation
            fi
        fi
        sleep 0.25
    done
else
    # Orientation fallback, stricter: only trigger on bottom-up (screen flipped flat)
    monitor-sensor | while read -r line; do
        case "$line" in
            *"Accelerometer orientation changed: "*)
                ori="${line##*: }"
                [[ $DEBUG -eq 1 ]] && echo "[DEBUG] Orientation: $ori"
                case "$ori" in
                    bottom-up)
                        if (( folded == 0 )); then
                            folded=1
                            log "Orientation bottom-up → rotate on"
                            start_rotation
                        fi
                        ;;
                    normal|undefined|*vertical*|left-up|right-up)
                        if (( folded == 1 )); then
                            folded=0
                            log "Orientation normal/vertical/side → rotate off"
                            stop_rotation
                        fi
                        ;;
                esac
                ;;
        esac
    done
fi
