#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
POLL_INTERVAL=2
STARTUP_GAP_1=0.40
STARTUP_GAP_2=0.60
DEBOUNCE_MS=150

DEVICE_NODE="${DEVICE_NODE:-}"
DEBUG=false

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--debug) DEBUG=true ;;
  esac
  shift
done

log() {
  if $DEBUG; then
    echo "$@"
  fi
}

on_tablet_mode() {
  log "[hook] Entered tablet mode"
  MONITOR=eDP-1 iio-hyprland eDP-1 &
  echo $! > /tmp/iio-hyprland.pid
}

on_laptop_mode() {
  log "[hook] Returned to laptop mode"
  if [[ -f /tmp/iio-hyprland.pid ]]; then
    kill "$(cat /tmp/iio-hyprland.pid)" 2>/dev/null || true
    rm -f /tmp/iio-hyprland.pid
  fi
  hyprctl reload >/dev/null 2>&1
}

find_event_node() {
  if [[ -n "$DEVICE_NODE" && -e "$DEVICE_NODE" ]]; then
    echo "$DEVICE_NODE"; return 0
  fi
  awk -v target="$DEVICE_NAME" '
    BEGIN { RS=""; FS="\n" }
    {
      ok=0; h="";
      for (i=1;i<=NF;i++) {
        if ($i ~ /^N: Name=/ && $i ~ "Name=\"" target "\"") ok=1
        if ($i ~ /^H: Handlers=/) h=$i
      }
      if (ok && h!="") {
        match(h, /event[0-9]+/)
        if (RSTART) { print "/dev/input/" substr(h, RSTART, RLENGTH); exit }
      }
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
      [[ "$v" == "1" ]] && { echo 1; return 0; }
      [[ "$v" == "0" ]] && { echo 0; return 0; }
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

startup_state() {
  local node="$1"
  local a b c sum
  a="$(read_state "$node")"
  sleep "$STARTUP_GAP_1"
  b="$(read_state "$node")"
  if [[ "$a" == "$b" ]]; then
    echo "$a"; return
  fi
  sleep "$STARTUP_GAP_2"
  c="$(read_state "$node")"
  sum=$((a + b + c))
  if (( sum >= 2 )); then echo 1; else echo 0; fi
}

now_ms() { date +%s%3N; }

main() {
  local node=""
  while true; do
    node="$(find_event_node || true)"
    if [[ -n "$node" && -e "$node" ]]; then
      log "[info] Monitoring ${DEVICE_NAME} at ${node}"
      break
    fi
    log "[warn] ${DEVICE_NAME} not found yet. Retrying in ${POLL_INTERVAL}s..."
    sleep "$POLL_INTERVAL"
  done

  current="$(startup_state "$node")"
  log "[startup] Current state: $([[ $current -eq 1 ]] && echo 'TABLET' || echo 'LAPTOP')]"

  # Fire initial hook
  if [[ $current -eq 1 ]]; then
    on_tablet_mode
  else
    on_laptop_mode
  fi

  last_change_ms="$(now_ms)"

  stdbuf -oL evtest "$node" | while IFS= read -r line; do
    if [[ "$line" =~ \(SW_TABLET_MODE\),\ value\ ([0-9]+) ]]; then
      new="${BASH_REMATCH[1]}"

      confirm="$(sysfs_state)"
      if [[ "$confirm" == "1" || "$confirm" == "0" ]]; then
        new="$confirm"
      fi

      now="$(now_ms)"
      delta=$(( now - last_change_ms ))

      if [[ "$new" != "$current" && $delta -ge $DEBOUNCE_MS ]]; then
        current="$new"
        last_change_ms="$now"
        if [[ $current -eq 1 ]]; then
          log "[event] -> Entered TABLET mode"
          on_tablet_mode
        else
          log "[event] -> Returned to LAPTOP mode"
          on_laptop_mode
        fi
      fi
    fi
  done
}

main
