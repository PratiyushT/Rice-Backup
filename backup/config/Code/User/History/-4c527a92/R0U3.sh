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
          if ($i ~ "
