#!/bin/bash

# Check power status using `cat /sys/class/power_supply/ADP0/online`
# 0 = running on battery
# 1 = plugged in

POWER_STATUS_FILE="/sys/class/power_supply/ADP0/online"

if [[ -f "$POWER_STATUS_FILE" && "$(cat $POWER_STATUS_FILE)" -eq 0 ]]; then
    notify-send "System has been inactive for almost 12 mins. System will be suspended in 20 secs."
fi
