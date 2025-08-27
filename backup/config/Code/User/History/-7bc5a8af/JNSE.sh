#!/bin/bash

# Usage:
# ./power-action.sh [suspend|dpms_off|brightness|lock|notify <message>] [ac|battery]

POWER_PATH="/sys/class/power_supply/ADP0/online"
ACTION="$1"
TARGET_POWER="$2"
shift 2
MESSAGE="$*"

if [ ! -f "$POWER_PATH" ]; then
    echo "Power status file not found: $POWER_PATH"
    exit 1
fi

ON_AC=$(cat "$POWER_PATH")

# If target power is specified, match it strictly
if [[ "$TARGET_POWER" == "battery" && "$ON_AC" -eq 1 ]]; then
    echo "On AC power – skipping action (target=battery)"
    exit 0
elif [[ "$TARGET_POWER" == "ac" && "$ON_AC" -eq 0 ]]; then
    echo "On battery – skipping action (target=ac)"
    exit 0
fi

notify() {
    notify-send -u normal "Power Action" "$1"
}

case "$ACTION" in
    suspend)
        pidof hyprlock >/dev/null || hyprlock &
        sleep 1
        systemctl suspend
        ;;
    dpms_off)
        hyprctl dispatch dpms off
        ;;
    brightness)
        brightnessctl -s && brightnessctl s 1%
        ;;
    lock)
        hyprlock &
        ;;
    notify)
        notify "$MESSAGE"
        ;;
    *)
        echo "Invalid action. Usage: $0 [suspend|dpms_off|brightness|lock|notify <message>] [ac|battery]"
        exit 1
        ;;
esac
