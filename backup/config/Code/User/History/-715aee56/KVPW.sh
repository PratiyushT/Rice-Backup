#!/usr/bin/env bash

# Get initial state
prev_state=$(< /sys/class/power_supply/ADP0/online)

while true; do
    sleep 1
    curr_state=$(< /sys/class/power_supply/ADP0/online)

    if [[ "$curr_state" != "$prev_state" ]]; then
        echo "Power state changed: $prev_state -> $curr_state"

        # Simulate mouse movement to reset idle
        ydotool mousemove -x 0.1 -y 0.1 && sleep 0.1 && ydotool mousemove -x -0.1 -y 0

        prev_state="$curr_state"
    fi
done
