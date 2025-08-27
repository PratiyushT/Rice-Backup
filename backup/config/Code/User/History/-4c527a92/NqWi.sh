#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
POLL_INTERVAL=2

on_tablet_mode() {
  echo "[hook] Entered tablet mode"
}

on_laptop_mode() {
  echo "[hook] Returned to laptop mode"
}

find_event_node() {
  awk -v target="$DEVICE_NAME" '
    BEGIN { RS=""; FS="\n" }
    {
      name_ok = 0
      handler = ""
      for (i=1; i<=NF; i++) {
        if ($i ~ /^N: Name=/) {
          if ($i ~ "Name=\"" target "\"") name_ok=1
        }
        if ($i ~ /^H: Handlers=/) {
          handler = $i
        }
      }
      if (name_ok && handler != "") {
        match(handler, /event[0-9]+/)
        if (RSTART) {
          print "/dev/input/" substr(handler, RSTART, RLENGTH)
          exit
        }
      }
    }
  ' /proc/bus/input/devices
}

query_state() {
  local node="$1"
  if evtest --query "$node" EV_SW SW_TABLET_MODE >/dev/null 2>&1; then
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

  # Just show current state, no hooks yet
  if query_state "$node"; then
    current=1
  else
    current=0
  fi
  ts="$(date '+%F %T')"
  echo "[${ts}] Current state: $([[ $current -eq 1 ]] && echo 'TABLET' || echo 'LAPTOP')"

  # Now only react when it changes
  stdbuf -oL evtest "$node" | while IFS= read -r line; do
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
