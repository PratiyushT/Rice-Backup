#!/usr/bin/env bash

DEVICE="platform::kbd_backlight"
iconsDir="$HOME/.config/hypr/Wallbash-Icon/media"

max=$(brightnessctl -d "$DEVICE" max 2>/dev/null)
val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)

# Calculate brightness percent
percent=$(( (val * 100 + (max / 2)) / max ))
angle="$(( ((percent + 2) / 5) * 5 ))"
ico="${iconsDir}/knob-${angle}.svg"

# Build dot bar
dots=$(seq -s "." $((percent / 15)) | sed 's/[0-9]//g')

# Device name
label="kbd_backlight"

# Show notification
notify-send -a "HyDE Notify" -r 9 -t 800 -i "$ico" "${percent}${dots}" "$label"

# Handle waybar --status call
if [[ "$1" == "--status" ]]; then
  echo "{\"text\": \"${percent}%\", \"percent\": $percent}"
  exit 0
fi

# Up/down control
case "$1" in
  up) brightnessctl -d "$DEVICE" set 1+ >/dev/null ;;
  down) brightnessctl -d "$DEVICE" set 1- >/dev/null ;;
  *) echo "Usage: $0 [--status|up|down]" && exit 1 ;;
esac
