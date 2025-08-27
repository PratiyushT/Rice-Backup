#!/bin/bash

# Path to AC adapter status
POWER_PATH="/sys/class/power_supply/ADP0/online"

# Check if the system is on battery
if [ -f "$POWER_PATH" ]; then
    if [ "$(cat "$POWER_PATH")" = "0" ]; then
        hyprctl dispatch dpms off
    fi
fi
