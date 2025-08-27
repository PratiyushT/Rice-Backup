#!/usr/bin/env bash

CM_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
NOTIFY_ID=1515  # Static ID to ensure notification replacement

# Get readable status
get_status_text() {
  if [[ -f "$CM_PATH" ]]; then
    val=$(< "$CM_PATH")
    [[ "$val" == "1" ]] && echo "ON" || echo "OFF"
  else
    echo "N/A"
  fi
}

# Send styled notification that replaces previous one
send_notification() {
  local title="$1"
  local message="$2"
  notify-send --app-name="ConservationMode" \
              --hint int:id:"$NOTIFY_ID" \
              "$title" "$message"
}

# Run the mode toggle as root using pkexec
set_conservation_mode() {
  local mode="$1"
  pkexec bash -c "echo '$mode' > '$CM_PATH'"
}

# Main execution
main() {
  if [[ "$1" == "--status" ]]; then
    status=$(get_status_text)
    echo "{\"text\": \"$status\"}"
    exit 0
  fi

  if [[ ! -f "$CM_PATH" ]]; then
    send_notification "Conservation Mode" "Unsupported on this device."
    exit 1
  fi

  curr=$(< "$CM_PATH")

  if [[ "$curr" == "1" ]]; then
    if set_conservation_mode 0; then
      send_notification "Conservation Mode Disabled" "Battery will now charge fully."
    else
      status=$(get_status_text)
      send_notification "Authentication Failed" "Conservation Mode remains $status."
    fi
  else
    if set_conservation_mode 1; then
      send_notification "Conservation Mode Enabled" "Battery will stop charging at ~77%."
    else
      status=$(get_status_text)
      send_notification "Authentication Failed" "Conservation Mode remains $status."
    fi
  fi
}

main "$@"
