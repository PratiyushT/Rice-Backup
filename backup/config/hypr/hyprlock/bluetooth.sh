#!/bin/bash
set -euo pipefail

config_file="$HOME/.config/hypr/hyprlock.conf"

# Read $bt-mode safely; default to false if missing or unreadable
bt_mode="$(sed -n 's/^[[:space:]]*\$bt-mode[[:space:]]*=[[:space:]]*\(true\|false\).*/\1/p' "$config_file" 2>/dev/null | head -n1)"
bt_mode="${bt_mode:-false}"

# Bluetooth power
bluetooth_status="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}')"
if [[ "${bluetooth_status:-no}" != "yes" ]]; then
  echo "󰂲  BT Off ..."
  exit 0
fi

# Collect connected device names
# Lines look like: "Device AA:BB:CC:DD:EE:FF Name With Spaces"
mapfile -t connected_names < <(bluetoothctl devices Connected 2>/dev/null | sed -n 's/^Device [^ ]\+ //p')

count=${#connected_names[@]}
if (( count == 0 )); then
  echo "󰂲  No Devices"
  exit 0
fi

# Truncate helper: 8 chars + "..."
truncate_name() {
  local n="$1"
  if (( ${#n} > 8 )); then
    printf '%s...\n' "${n:0:8}"
  else
    printf '%s\n' "$n"
  fi
}

if [[ "$bt_mode" != "true" ]]; then
  # bt-mode=false → always generic when any device is connected
  echo "󰂯  Connected"
  exit 0
fi

# bt-mode=true
if (( count == 1 )); then
  one_name="$(truncate_name "${connected_names[0]}")"
  echo "󰂯  $one_name"
else
  echo "󰂯  Connected (${count})"
fi
