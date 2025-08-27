#!/usr/bin/env bash
set -euo pipefail

MONITOR="${MONITOR:-eDP-1}"
MASTER_FLAG="${MASTER_FLAG:-}"     # e.g. --right-master or --left-master
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
PID_FILE="$RUNTIME_DIR/iio-hyprland.pid"

# Hinge thresholds if we must use hinge angle
HINGE_ON="${HINGE_ON:-240}"
HINGE_OFF="${HINGE_OFF:-210}"

DEBUG=0
[[ "${1:-}" == "-d" ]] && DEBUG=1
log(){ [[ $DEBUG -eq 1 ]] && echo "[DEBUG] $*"; }

# Capture the original monitor settings once, to restore later
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
    log "Restoring monitor to: $ORIG_MONITOR_LINE"
    hyprctl keyword monitor "$ORIG_MONITOR_LINE,transform,0" >/dev/null 2>&1 || true
  fi
}

# ---------- Signal discovery ----------

# 1) Tablet-mode switch via sysfs
find_tablet_switch_state() {
  # Look for /sys/class/switch/*/name == "tablet-mode"
  local sw
  for sw in /sys/class/switch/*; do
    [[ -r "$sw/name" ]] || continue
    if [[ "$(cat "$sw/name" 2>/dev/null)" == "tablet-mode" ]]; then
      echo "$sw/state"
      return 0
    fi
  done
  return 1
}

# 2) Hinge angle in IIO
find_hinge_file() {
  local f
  for f in /sys/bus/iio/devices/iio:device*/in_hinge_angle_input \
           /sys/bus/iio/devices/iio:device*/in_hinge_*_input \
           /sys/bus/iio/devices/iio:device*/in_*_hinge*_input; do
    [[ -r "$f" ]] && { echo "$f"; return 0; }
  done
  return 1
}

# 3) Orientation via iio-sensor-proxy
have_monitor_sensor() {
  command -v monitor-sensor >/dev/null 2>&1
}

TABLET_STATE_FILE=""
HINGE_FILE=""
MODE=""

if TABLET_STATE_FILE="$(find_tablet_switch_state)"; then
  MODE="tablet-switch"
  log "Using tablet-mode switch: $TABLET_STATE_FILE"
elif HINGE_FILE="$(find_hinge_file)"; then
  MODE="hinge"
  log "Using hinge angle: $HINGE_FILE"
elif have_monitor_sensor; then
  MODE="orientation"
  log "Using orientation fallback (monitor-sensor)"
else
  echo "No usable tablet signal found. Exiting." >&2
  exit 1
fi

# ---------- Main loops ----------

folded=0

if [[ "$MODE" == "tablet-switch" ]]; then
  # Read /sys/class/switch/.../state (1 = tablet, 0 = laptop) in a tiny poll loop
  last=""
  while true; do
    cur="$(cat "$TABLET_STATE_FILE" 2>/dev/null || echo 0)"
    if [[ "$cur" != "$last" ]]; then
      if [[ "$cur" == "1" ]]; then
        log "Tablet switch: ON → rotate on"
        folded=1
        start_rotation()
      else
        log "Tablet switch: OFF → rotate off"
        folded=0
        stop_rotation()
      fi
      last="$cur"
    fi
    sleep 0.25
  done

elif [[ "$MODE" == "hinge" ]]; then
  # Hinge angle with hysteresis
  while true; do
    ANGLE="$(cat "$HINGE_FILE" 2>/dev/null || echo 0)"
    if (( folded == 0 )) && (( ANGLE >= HINGE_ON )); then
      folded=1; log "Angle >= $HINGE_ON → rotate on"; start_rotation
    elif (( folded == 1 )) && (( ANGLE <= HINGE_OFF )); then
      folded=0; log "Angle <= $HINGE_OFF → rotate off"; stop_rotation
    fi
    [[ $DEBUG -eq 1 ]] && echo "[DEBUG] Angle: $ANGLE"
    sleep 0.25
  done

else
  # Orientation fallback. Only consider fully flipped tablet posture.
  monitor-sensor | while read -r line; do
    case "$line" in
      *"Accelerometer orientation changed: "*)
        ori="${line##*: }"
        [[ $DEBUG -eq 1 ]] && echo "[DEBUG] Orientation: $ori"
        case "$ori" in
          bottom-up)
            if (( folded == 0 )); then
              folded=1; log "Orientation bottom-up → rotate on"; start_rotation
            fi
            ;;
          normal|undefined|*vertical*|left-up|right-up)
            if (( folded == 1 )); then
              folded=0; log "Orientation not tablet → rotate off"; stop_rotation
            fi
            ;;
        esac
        ;;
    esac
  done
fi
