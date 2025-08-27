#!/usr/bin/env bash

CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

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
curr=$(< "$CM_PATH")

if [[ "$curr" == "1" ]]; then
  if pkexec /home/PrT15/.local/lib/hyde/set-conservation-mode.sh 0; then
    notify-send "Conservation Mode Disabled" "Battery will now charge fully."
  fi
else
  if pkexec /home/PrT15/.local/lib/hyde/set-conservation-mode.sh 1; then
    notify-send "Conservation Mode Enabled" "Battery will stop charging at ~77%."
  fi
fi
