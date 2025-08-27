#!/usr/bin/env bash

CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
SCRIPT_PATH="/home/PrT15/.local/lib/hyde/set-conservation-mode.sh"

get_status_text() {
  local val
  if [[ -f "$CM_PATH" ]]; then
    val=$(< "$CM_PATH")
    [[ "$val" == "1" ]] && echo "ON" || echo "OFF"
  else
    echo "N/A"
  fi
}

if [[ "$1" == "--status" ]]; then
  status=$(get_status_text)
  echo "{\"text\": \"$status\"}"
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
    curr_status=$(get_status_text)
    notify-send "Authentication Failed" "Conservation Mode remains $curr_status."
  fi
else
  if pkexec "$SCRIPT_PATH" 1; then
    notify-send "Conservation Mode Enabled" "Battery will stop charging at ~77%."
  else
    curr_status=$(get_status_text)
    notify-send "Authentication Failed" "Conservation Mode remains $curr_status."
  fi
fi
