#!/bin/bash

# Usage:
# ./power-action.sh [suspend|dpms_off|brightness|lock|notify <message>]

POWER_PATH="/sys/class/power_supply/ADP0/online"
ACTION="$1"
shift
MESSAGE="$*"

if [ ! -f "$POWER_PATH" ]; then
    echo "Power status file not found: $POWER_PATH"
    exit 1
fi

ON_AC=$(cat "$POWER_PATH")

if [[ "$ON_AC" -eq 1 ]]; then
    # On AC power, skip all actions
    echo "System is on AC power. Skipping......"
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
        echo "Invalid action. Usage: $0 [suspend|dpms_off|brightness|lock|notify <message>]"
        exit 1
        ;;
esac
