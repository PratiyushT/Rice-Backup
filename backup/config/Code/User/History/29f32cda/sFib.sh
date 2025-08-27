#!/bin/bash

POWER_PATH="/sys/class/power_supply/ADP0/online"

if [ ! -f "$POWER_PATH" ]; then
    echo "Power status file not found: $POWER_PATH"
    exit 1
fi

# 0 = on battery, 1 = charging
if [[ "$(cat "$POWER_PATH")" -eq 0 ]]; then
    # Lock the session before suspending
    hyprctl dispatch dpms off
    pidof hyprlock >/dev/null || hyprlock & sleep 1  # or replace `hyprlock` with your locker
    systemctl suspend
else
    echo "On AC power - skipping suspend"
fi
