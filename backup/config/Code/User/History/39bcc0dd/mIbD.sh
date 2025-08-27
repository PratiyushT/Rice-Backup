#!/bin/bash

POWER_PATH="/sys/class/power_supply/ADP0/online"

if [ ! -f "$POWER_PATH" ]; then
    echo "Power status file not found: $POWER_PATH"
    exit 1
fi

# 0 = on battery, 1 = charging
if [[ "$(cat "$POWER_PATH")" -eq 0 ]]; then
    hyprctl dispatch dpms off
else
    "On AC power - skipping DPMS Off"
fi
