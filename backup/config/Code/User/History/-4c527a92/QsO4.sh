#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
POLL_INTERVAL=0

# Optional: override the event node via env var for debugging
#   DEVICE_NODE=/dev/input/event8 ./iio-rotate-when-tablet.sh -d
DEVICE_NODE="${DEVICE_NODE:-}"

# Hooks. They only run on real changes after startup.
on_tablet_mode() {
  echo "[hook] Entered tablet mode"
  # put your rotation or HyDE actions here
}
on_laptop_mode() {
  echo "[hook] Returned to laptop mode"
  # put your rotation or HyDE actions here
}

find_event_node() {
  if [[ -n "$DEVICE_NODE" && -e "$DEVICE_NODE" ]]; then
    echo "$DEVICE_NODE"
    return 0
  fi
  awk -v target="$DEVICE_NAME" '
    BEGIN { RS=""; FS="\n" }
    {
      name_ok = 0
      handler = ""
      for (i=1; i<=NF; i++) {
        if ($i ~ /^N: Name=/ && $i ~ "Name=\"" target "\"") name_ok=1
        if ($i ~ /^H: Handlers=/) handler = $i
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

# Read current state from sysfs if available. Returns 1 for tablet, 0 for laptop.
sysfs_state() {
  local p
  for p in \
    /sys/class/switch/tablet-mode/state \
    /sys/devices/platform/thinkpad_acpi/hotkey_tablet_mode \
    /sys/bus/platform/devices/ideapad_acpi/*/tablet_mode \
    /sys/bus/platform/devices/ideapad_acpi/*/switch; do
    if [[ -r "$p" ]]; then
      v="$(tr -cd '0-9' < "$p" || true)"
      if [[ "$v" == "1" ]]; then echo 1; return 0; fi
      if [[ "$v" == "0" ]]; then echo 0; return 0; fi
    fi
  done
  echo ""
}

# Fallback only if sysfs does not tell us. Uses evtest --query.
evtest_state() {
  local node="$1"
  # evtest --query exits 0 when a switch is ON and 10 when OFF
  if evtest --query "$node" EV_SW SW_TABLET_MODE >/dev/null 2>&1; then
    echo 1
  else
    echo 0
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

  # Baseline from sysfs first. Only fall back to evtest if sysfs is unavailable.
  local current_str=""
  local s="$(sysfs_state)"
  if [[ "$s" == "1" ]]; then
    current=1
    current_str="TABLET"
  elif [[ "$s" == "0" ]]; then
    current=0
    current_str="LAPTOP"
  else
    current="$(evtest_state "$node")"
    current_str=$([[ $current -eq 1 ]] && echo "TABLET" || echo "LAPTOP")
  fi

  ts="$(date '+%F %T')"
  echo "[${ts}] Current state: ${current_str}"

  # Only react to real changes after startup
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
