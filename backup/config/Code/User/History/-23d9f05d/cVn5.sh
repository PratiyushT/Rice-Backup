#!/bin/bash

# Usage: notify-if-on-battery.sh "Message to show"

MESSAGE="${1:-System will be suspended soon.}"
POWER_PATH="/sys/class/power_supply/ADP0/online"

if [[ -f "$POWER_PATH" && "$(cat $POWER_PATH)" -eq 0 ]]; then
    notify-send "$MESSAGE"
fi
