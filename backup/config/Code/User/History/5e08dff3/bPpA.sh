#!/usr/bin/env bash

CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
SCRIPT_PATH="/home/PrT15/.local/lib/hyde/set-conservation-mode.sh"
NOTIFY_ID_FILE="/tmp/.conservation_notify_id"

get_status_text() {
  local val
  if [[ -f "$CM_PATH" ]]; then
    val=$(< "$CM_PATH")
    [[ "$val" == "1" ]] && echo "ON" || echo "OFF"
  else
    echo "N/A"
  fi
}

send_notification() {
  local title="$1"
  local body="$2"
  local replace_id=0

  if [[ -f "$NOTIFY_ID_FILE" ]]; then
    replace_id=$(< "$NOTIFY_ID_FILE")
  fi

  # Send notification and capture the new ID
  new_id=$(notify-send --app-name="ConservationMode" --hint int:id:"$replace_id" \
    --print-id "$title" "$body")

  echo "$new_id" > "$NOTIFY_ID_FILE"
}

if [[ "$1" == "--status" ]]; then
  status=$(get_status_text)
  echo "{\"text\": \"$status\"}"
  exit 0
fi

# toggle logic
if [[ ! -f "$CM_PATH" ]]; then
  send_notification "Conservation Mode" "Unsupported on this device."
  exit 1
fi

curr=$(< "$CM_PATH")

if [[ "$curr" == "1" ]]; then
  if pkexec "$SCRIPT_PATH" 0; then
    send_notification "Conservation Mode Disabled" "Battery will now charge fully."
  else
    curr_status=$(get_status_text)
    send_notification "Authentication Failed" "Conservation Mode remains $curr_status."
  fi
else
  if pkexec "$SCRIPT_PATH" 1; then
    send_notification "Conservation Mode Enabled" "Battery will stop charging at ~77%."
  else
    curr_status=$(get_status_text)
    send_notification "Authentication Failed" "Conservation Mode remains $curr_status."
  fi
fi
