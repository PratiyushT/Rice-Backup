#!/usr/bin/env bash
set -euo pipefail

# Config
DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"  # exact match from your hyprctl -j devices
POLL_INTERVAL=2

# Hooks. Replace the echo commands with what you want.
on_tablet_mode() {
  # Examples:
  # hyprctl keyword input:kb_options "ctrl:nocaps"
  # notify-send "Tablet mode ON"
  echo "[hook] Entered tablet mode"
}

on_laptop_mode() {
  # Examples:
  # notify-send "Tablet mode OFF"
  echo "[hook] Returned to laptop mode"
}

# Find the event node for the given input device name by parsing /proc/bus/input/devices
find_event_node() {
  awk -v target="$DEVICE_NAME" '
    BEGIN { RS=""; FS="\n" }
    {
      name_ok = 0
      handler = ""
      for (i=1; i<=NF; i++) {
        if ($i ~ /^N: Name=/) {
          # line like: N: Name="Lenovo Yoga Tablet Mode Control switch"
          if ($i ~ "Name=\"" target "\"") name_ok=1
        }
        if ($i ~ /^H: Handlers=/) {
          handler = $i
        }
      }
      if (name_ok && handler != "") {
        # extract eventX from Handlers
        match(handler, /event[0-9]+/)
        if (RSTART) {
          print "/dev/input/" substr(handler, RSTART, RLENGTH)
          exit
        }
      }
    }
  ' /proc/bus/input/devices
}

# Query current state with evtest --query
query_state() {
  local node="$1"
  # Returns 1 in tablet mode, 0 in laptop mode
  if evtest --query "$node" EV_SW SW_TABLET_MODE >/dev/null 2>&1; then
    # evtest --query exits 0 when the switch is ON, 1 when OFF
    # So invert using the exit code
    return 0
  else
    return 1
  fi
}

main() {
  local node=""
  while true; do
    node="$(find_event_node || true)"
    if [[ -n "${node}" && -e "${node}" ]]; then
      echo "[info] Monitoring ${DEVICE_NAME} at ${node}"
      break
    fi
    echo "[warn] ${DEVICE_NAME} not found yet. Retrying in ${POLL_INTERVAL}s..."
    sleep "${POLL_INTERVAL}"
  done

  # Determine initial state
  if query_state "$node"; then
    current=1
  else
    current=0
  fi
  ts="$(date '+%F %T')"
  echo "[${ts}] Initial state: $([[ $current -eq 1 ]] && echo 'TABLET' || echo 'LAPTOP')"

  # Fire initial hook to sync environment if desired
  if [[ $current -eq 1 ]]; then on_tablet_mode; else on_laptop_mode; fi

  # Stream events and react to SW_TABLET_MODE changes
  stdbuf -oL evtest "$node" | while IFS= read -r line; do
    # Lines look like: Event: time 1723563307.123456, type 5 (EV_SW), code 1 (SW_TABLET_MODE), value 1
    if [[ "$line" =~ \(SW_TABLET_MODE\),\ value\ ([0-9]+) ]]; then
      new="${BASH_REMATCH[1]}"
      if [[ "$new" != "$current" ]]; then
        current="$new"
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
