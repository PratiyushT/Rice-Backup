#!/usr/bin/env bash
set -euo pipefail

# ------------ Config ------------
DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
MONITOR_NAME="${MONITOR_NAME:-eDP-1}"      # set via env if different
PID_FILE="/tmp/iio-hyprland.pid"
POLL_INTERVAL=2                             # seconds between re-detect attempts
DEBOUNCE_MS=150                             # ignore flips faster than this
DEBUG=0
[[ "${1:-}" == "-d" ]] && DEBUG=1

log() { [[ $DEBUG -eq 1 ]] && echo "$@"; }

# ------------ Hooks ------------
start_rotation() {
  if [[ -f "$PID_FILE" ]]; then
    local pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      if ps -p "$pid" -o cmd= 2>/dev/null | grep -q "iio-hyprland"; then
        log "[hook] iio-hyprland already running (PID $pid)"
        return
      fi
    fi
  fi

  log "[hook] Tablet mode ON — starting rotation"
  MONITOR="$MONITOR_NAME" iio-hyprland "$MONITOR_NAME" &
  echo $! > "$PID_FILE"
}

stop_rotation() {
  log "[hook] Tablet mode OFF — stopping rotation"
  if [[ -f "$PID_FILE" ]]; then
    local pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      if ps -p "$pid" -o cmd= 2>/dev/null | grep -q "iio-hyprland"; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
      fi
    fi
    rm -f "$PID_FILE"
  fi
  hyprctl reload >/dev/null 2>&1 || true
}

# Cleanup on exit
cleanup() {
  log "[info] Cleaning up…"
  stop_rotation
}
trap cleanup EXIT

# ------------ Helpers ------------
find_event_file() {
  awk -v target="$DEVICE_NAME" '
    BEGIN { RS=""; FS="\n" }
    {
      ok=0; ev="";
      for (i=1;i<=NF;i++) {
        if ($i ~ /^N: Name=/ && $i ~ "Name=\"" target "\"") ok=1
        if ($i ~ /^H: Handlers=/ && match($i, /event[0-9]+/, m)) ev=m[0]
      }
      if (ok && ev!="") { print "/dev/input/" ev; exit }
    }
  ' /proc/bus/input/devices
}

sysfs_state() {
  local p v
  for p in \
    /sys/class/switch/tablet-mode/state \
    /sys/devices/platform/thinkpad_acpi/hotkey_tablet_mode \
    /sys/bus/platform/devices/ideapad_acpi/*/tablet_mode \
    /sys/bus/platform/devices/ideapad_acpi/*/switch
  do
    if [[ -r "$p" ]]; then
      v="$(tr -cd '0-9' < "$p" || true)"
      [[ "$v" == "1" || "$v" == "0" ]] && { echo "$v"; return; }
    fi
  done
  echo ""
}

evtest_state() {
  local node="$1"
  if evtest --query "$node" EV_SW SW_TABLET_MODE >/dev/null 2>&1; then
    echo 1
  else
    echo 0
  fi
}

read_state() {
  local node="$1"
  local s="$(sysfs_state)"
  if [[ "$s" == "1" || "$s" == "0" ]]; then
    echo "$s"
  else
    echo "$(evtest_state "$node")"
  fi
}

stable_state() {
  local node="$1" last="" count=0 s
  while true; do
    s="$(read_state "$node")"
    if [[ -n "$s" && "$s" == "$last" ]]; then
      ((count++))
      if (( count >= 3 )); then echo "$s"; return; fi
    else
      last="$s"; count=1
    fi
    sleep 0.2
  done
}

now_ms() { date +%s%3N; }

# ------------ Main loop ------------
while true; do
  EVENT_FILE="$(find_event_file || true)"
  if [[ -z "$EVENT_FILE" || ! -e "$EVENT_FILE" ]]; then
    log "[warn] ${DEVICE_NAME} not found. Retrying in ${POLL_INTERVAL}s…"
    sleep "$POLL_INTERVAL"
    continue
  fi

  log "[info] Monitoring on: $EVENT_FILE"

  CURRENT="$(stable_state "$EVENT_FILE")"
  log "[info] Initial mode: $([[ "$CURRENT" -eq 1 ]] && echo TABLET || echo LAPTOP)"
  if [[ "$CURRENT" -eq 1 ]]; then start_rotation; else stop_rotation; fi

  LAST_CHANGE_MS="$(now_ms)"

  stdbuf -oL evtest "$EVENT_FILE" 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" =~ \(SW_TABLET_MODE\),\ value\ ([0-9]+) ]]; then
      NEW="${BASH_REMATCH[1]}"
      CONFIRM="$(sysfs_state)"
      if [[ "$CONFIRM" == "1" || "$CONFIRM" == "0" ]]; then
        NEW="$CONFIRM"
      fi

      NOW="$(now_ms)"; DELTA=$(( NOW - LAST_CHANGE_MS ))
      if [[ "$NEW" != "$CURRENT" && $DELTA -ge $DEBOUNCE_MS ]]; then
        CURRENT="$NEW"; LAST_CHANGE_MS="$NOW"
        if [[ "$CURRENT" -eq 1 ]]; then
          log "[event] -> TABLET"
          start_rotation
        else
          log "[event] -> LAPTOP"
          stop_rotation
        fi
      fi
    fi
  done

  log "[warn] evtest exited; re-detecting device…"
  sleep 1
done
