#!/usr/bin/env bash

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
  echo 0 | sudo tee "$CM_PATH" >/dev/null
  notify-send "Conservation Mode Disabled" "Battery will now charge fully."
else
  echo 1 | sudo tee "$CM_PATH" >/dev/null
  notify-send "Conservation Mode Enabled" "Battery will stop charging at ~77%."
fi
