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

notify() {
    notify-send -u normal "Power Action" "$1"
}

case "$ACTION" in
    suspend)
        if [[ "$ON_AC" -eq 0 ]]; then
            pidof hyprlock >/dev/null || hyprlock &
            sleep 1
            systemctl suspend
        fi
        ;;
    dpms_off)
        if [[ "$ON_AC" -eq 0 ]]; then
            hyprctl dispatch dpms off
        fi
        ;;
    brightness)
       if [[ "$ON_AC" -eq 0 ]]; then
           { brightnessctl -s && brightnessctl s 1% ;}
        fi
        ;;
    lock)
        hyprlock &
        ;;
    notify)
        if [[ "$ON_AC" -eq 0 ]]; then
            notify "$MESSAGE"
        fi
        ;;
    *)
        echo "Invalid action. Usage: $0 [suspend|dpms_off|brightness|lock|notify <message>]"
        exit 1
        ;;
esac
