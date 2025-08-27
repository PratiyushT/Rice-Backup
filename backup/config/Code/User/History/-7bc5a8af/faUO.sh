#!/bin/bash

# Usage:
# ./power-action.sh suspend
# ./power-action.sh dpms_off
# ./power-action.sh brightness
# ./power-action.sh lock

POWER_PATH="/sys/class/power_supply/ADP0/online"
ACTION="$1"

if [ -z "$ACTION" ]; then
    echo "No action provided. Usage: $0 [suspend|dpms_off|brightness|lock]"
    exit 1
fi

if [ ! -f "$POWER_PATH" ]; then
    echo "Power status file not found: $POWER_PATH"
    exit 1
fi

ON_AC=$(cat "$POWER_PATH")

case "$ACTION" in
    suspend)
        if [[ "$ON_AC" -eq 0 ]]; then
            pidof hyprlock >/dev/null || hyprlock &
            sleep 1
            systemctl suspend
        else
            echo "On AC power - skipping suspend"
        fi
        ;;
    dpms_off)
        if [[ "$ON_AC" -eq 0 ]]; then
            hyprctl dispatch dpms off
        else
            echo "On AC power - skipping dpms off"
        fi
        ;;
    brightness)
        if [[ "$ON_AC" -eq 0 ]]; then
            # Reduce brightness to 1%
            BRIGHTNESS_DIR=$(find /sys/class/backlight -maxdepth 1 -type d | grep -v "/sys/class/backlight$" | head -n 1)
            if [ -z "$BRIGHTNESS_DIR" ]; then
                echo "No backlight directory found"
                exit 1
            fi
            MAX_BRIGHTNESS=$(cat "$BRIGHTNESS_DIR/max_brightness")
            ONE_PERCENT=$((MAX_BRIGHTNESS / 100))
            echo "$ONE_PERCENT" | sudo tee "$BRIGHTNESS_DIR/brightness" >/dev/null
        else
            echo "On AC power - skipping brightness adjustment"
        fi
        ;;
    lock)
        hyprlock &
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Usage: $0 [suspend|dpms_off|brightness|lock]"
        exit 1
        ;;
esac
