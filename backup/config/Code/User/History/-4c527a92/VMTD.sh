#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"
MASTER_FLAG="${MASTER_FLAG:-}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"

HINGE_ON="${HINGE_ON:-240}"
HINGE_OFF="${HINGE_OFF:-210}"

DEBUG=0
[[ "${1:-}" == "-d" ]] && DEBUG=1

log() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "[DEBUG] $*"
    fi
}

start_rotation() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log "Already running"
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
    hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,0" >/dev/null 2>&1 || true
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
else
    MODE="orientation"
fi

folded=0

if [[ "$MODE" == "hinge" ]]; then
    while true; do
        if ANGLE="$(cat "$HINGE_FILE" 2>/dev/null)"; then
            if [[ $DEBUG -eq 1 ]]; then
                echo "[DEBUG] Angle: $ANGLE"
            fi
            if (( folded == 0 )) && (( ANGLE >= HINGE_ON )); then
                folded=1
                log ">= $HINGE_ON → rotate on"
                start_rotation
            elif (( folded == 1 )) && (( ANGLE <= HINGE_OFF )); then
                folded=0
                log "<= $HINGE_OFF → rotate off"
                stop_rotation
            fi
        fi
        sleep 0.25
    done
else
    monitor-sensor | while read -r line; do
        case "$line" in
            *"Accelerometer orientation changed: "*)
                ori="${line##*: }"
                if [[ $DEBUG -eq 1 ]]; then
                    echo "[DEBUG] Orientation: $ori"
                fi
                case "$ori" in
                    bottom-up|right-up|left-up)
                        if (( folded == 0 )); then
                            folded=1
                            log "orientation → rotate on"
                            start_rotation
                        fi
                        ;;
                    normal|undefined|*vertical*)
                        if (( folded == 1 )); then
                            folded=0
                            log "orientation → rotate off"
                            stop_rotation
                        fi
                        ;;
                esac
                ;;
        esac
    done
fi
