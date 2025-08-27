#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
POLL_INTERVAL=2
STARTUP_GAP_1=0.40      # seconds between first and second read
STARTUP_GAP_2=0.60      # seconds before third read if needed
DEBOUNCE_MS=150         # ignore toggles within this many ms

# Optional: set DEVICE_NODE to skip auto-detect, e.g. DEVICE_NODE=/dev/input/event8 ./iio-rotate-when-tablet.sh -d
DEVICE_NODE="${DEVICE_NODE:-}"

on_tablet_mode() {
  echo "[hook] Entered tablet mode"
  # Start iio-hyprland rotation (example monitor eDP-1)
  MONITOR=eDP-1 iio-hyprland eDP-1 &
  echo $! > /tmp/iio-hyprland.pid
}

on_laptop_mode() {
  echo "[hook] Returned to laptop mode"
  # Stop rotation
  if [[ -f /tmp/iio-hyprland.pid ]]; then
    kill "$(cat /tmp/iio-hyprland.pid)" 2>/dev/null || true
    rm -f /tmp/iio-hyprland.pid
  fi
  # Restore original monitor settings
  hyprctl reload   # or hyprctl keyword monitor "eDP-1,2880x1800@90,0x0,1"
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

# Return 1 for tablet, 0 for laptop
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
  sum=$((a + b + c))           # since values are 0 or 1
  if (( sum >= 2 )); then echo 1; else echo 0; fi
}

now_ms() { date +%s%3N; }     # milliseconds since epoch (GNU date on Arch)

main() {
  local node=""
  while true; do
    node="$(find_event_node || true)"
    if [[ -n "$node" && -e "$node" ]]; then
      echo "[info] Monitoring ${DEVICE_NAME} at ${node}"
      break
    fi
    echo "[warn] ${DEVICE_NAME} not found yet. Retrying in ${POLL_INTERVAL}s..."
    sleep "$POLL_INTERVAL"
  done

  # Majority-vote baseline, no hooks fired here
  current="$(startup_state "$node")"
  ts="$(date '+%F %T')"
  echo "[${ts}] Current state: $([[ $current -eq 1 ]] && echo 'TABLET' || echo 'LAPTOP')]"

  last_change_ms="$(now_ms)"

  # Stream changes and debounce brief flaps
  stdbuf -oL evtest "$node" | while IFS= read -r line; do
    if [[ "$line" =~ \(SW_TABLET_MODE\),\ value\ ([0-9]+) ]]; then
      new="${BASH_REMATCH[1]}"

      # Optional confirm with a quick sysfs recheck to reduce false edges
      confirm="$(sysfs_state)"
      if [[ "$confirm" == "1" || "$confirm" == "0" ]]; then
        new="$confirm"
      fi

      now="$(now_ms)"
      delta=$(( now - last_change_ms ))

      if [[ "$new" != "$current" && $delta -ge $DEBOUNCE_MS ]]; then
        current="$new"
        last_change_ms="$now"
        ts="$(date '+%F %T')"
        if [[ $current -eq 1 ]]; then
          echo "[${ts}] -> Entered TABLET mode"
          on_tablet_mode
        else
          echo "[${ts}] -> Returned to LAPTOP mode"
          on_laptop_mode
        fi
      fi
    fi
  done
}

main
