#!/bin/bash

# Usage: ./power-action.sh [suspend|dpms_off|brightness|lock]

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

notify() {
    MESSAGE="$1"
    notify-send -u normal "Power Action" "$MESSAGE"
}

case "$ACTION" in
    suspend)
        if [[ "$ON_AC" -eq 0 ]]; then
            notify "Suspending (on battery)..."
            pidof hyprlock >/dev/null || hyprlock &
            sleep 1
            systemctl suspend
        else
            notify "On AC power – skipping suspend"
        fi
        ;;
    dpms_off)
        if [[ "$ON_AC" -eq 0 ]]; then
            notify "Turning off display (on battery)..."
            hyprctl dispatch dpms off
        else
            notify "On AC power – skipping display off"
        fi
        ;;
    brightness)
        if [[ "$ON_AC" -eq 0 ]]; then
            notify "Reducing brightness to 1% (on battery)..."
            BRIGHTNESS_DIR=$(find /sys/class/backlight -maxdepth 1 -type d | grep -v "/sys/class/backlight$" | head -n 1)
            if [ -z "$BRIGHTNESS_DIR" ]; then
                notify "No backlight directory found"
                exit 1
            fi
            MAX_BRIGHTNESS=$(cat "$BRIGHTNESS_DIR/max_brightness")
            ONE_PERCENT=$((MAX_BRIGHTNESS / 100))
            echo "$ONE_PERCENT" | sudo tee "$BRIGHTNESS_DIR/brightness" >/dev/null
        else
            notify "On AC power – skipping brightness adjustment"
        fi
        ;;
    lock)
        notify "Locking screen..."
        hyprlock &
        ;;
    *)
        notify "Invalid action: $ACTION"
        echo "Usage: $0 [suspend|dpms_off|brightness|lock]"
        exit 1
        ;;
esac
