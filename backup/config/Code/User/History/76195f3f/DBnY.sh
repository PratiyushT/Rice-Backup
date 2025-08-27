#!/usr/bin/env bash

DEVICE="platform::kbd_backlight"

max=$(brightnessctl -d "$DEVICE" max 2>/dev/null)
val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)

# Handle command-line args
case "$1" in
  --status)
    if [[ -n "$val" && -n "$max" && "$max" -gt 0 ]]; then
      percent=$(( val * 100 / max ))
      index=$(( percent * 9 / 101 ))
      icons=(        )
      icon="${icons[$index]}"
      echo "{\"text\": \"$percent\", \"percent\": $percent, \"icon\": \"$icon\"}"
    else
      echo '{"text": "N/A", "percent": 0, "icon": ""}'
    fi
    exit 0
    ;;
  up)
    brightnessctl -d "$DEVICE" set 1+ >/dev/null
    ;;
  down)
    brightnessctl -d "$DEVICE" set 1- >/dev/null
    ;;
  *)
    echo "Usage: $0 [--status|up|down]"
    exit 1
    ;;
esac
