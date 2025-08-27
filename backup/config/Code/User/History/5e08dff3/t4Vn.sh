#!/usr/bin/env bash

WRAPPER="/home/PrT15/.local/lib/hyde/set-conservation-mode.sh"
CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

if [[ "$1" == "--status" ]]; then
  if [[ -f "$CM_PATH" ]]; then
    val=$(< "$CM_PATH")
    echo "{\"text\": \"\", \"icon\": \"$val\"}"
  else
    echo "{\"text\": \"\", \"icon\": \"\"}"
  fi
  exit 0
fi

if [[ ! -f "$CM_PATH" ]]; then
  notify-send "Conservation Mode" "Not supported on this device."
  exit 1
fi

curr=$(< "$CM_PATH")

if [[ "$curr" == "1" ]]; then
  pkexec "$WRAPPER" 0 && notify-send "Conservation Mode Disabled" "Battery will now charge fully."
else
  pkexec "$WRAPPER" 1 && notify-send "Conservation Mode Enabled" "Battery will stop charging at ~77%."
fi
