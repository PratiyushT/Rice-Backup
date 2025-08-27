#!/usr/bin/env bash

CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
SCRIPT_PATH="/home/PrT15/.local/lib/hyde/set-conservation-mode.sh"

if [[ "$1" == "--status" ]]; then
  if [[ -f "$CM_PATH" ]]; then
    val=$(tr -d '\n' < "$CM_PATH")
    if [[ "$val" == "1" ]]; then
      echo '{"text": "ON"}'
    else
      echo '{"text": "OFF"}'
    fi
  else
    echo '{"text": "N/A"}'
  fi
  exit 0
fi

# toggle logic
if [[ ! -f "$CM_PATH" ]]; then
  notify-send "Conservation Mode" "Unsupported on this device."
  exit 1
fi

curr=$(< "$CM_PATH")

if [[ "$curr" == "1" ]]; then
  if pkexec "$SCRIPT_PATH" 0; then
    notify-send "Conservation Mode Disabled" "Battery will now charge fully."
  else
    notify-send "Conservation Mode" "Authentication failed. No changes made."
  fi
else
  if pkexec "$SCRIPT_PATH" 1; then
    notify-send "Conservation Mode Enabled" "Battery will stop charging at ~77%."
  else
    notify-send "Conservation Mode" "Authentication failed. No changes made."
  fi
fi
