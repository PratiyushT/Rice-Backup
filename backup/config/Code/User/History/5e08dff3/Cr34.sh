#!/usr/bin/env bash

CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

if [[ ! -f "$CM_PATH" ]]; then
  notify-send "Conservation Mode" "Not supported on this device."
  exit 1
fi

current=$(< "$CM_PATH")

choice=$(gum choose "0  Disable Conservation Mode" "1  Enable Conservation Mode")

if [[ "$choice" == "0  Disable Conservation Mode" ]]; then
  echo 0 | sudo tee "$CM_PATH" >/dev/null
  notify-send "Conservation Mode Disabled" "Battery will charge fully."
elif [[ "$choice" == "1  Enable Conservation Mode" ]]; then
  echo 1 | sudo tee "$CM_PATH" >/dev/null
  notify-send "Conservation Mode Enabled" "Battery will stop charging at ~77%."
fi
