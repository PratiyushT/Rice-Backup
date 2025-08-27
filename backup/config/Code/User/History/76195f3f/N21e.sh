#!/usr/bin/env bash

DEVICE="platform::kbd_backlight"

max=$(brightnessctl -d "$DEVICE" max 2>/dev/null)
val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)

get_icon_and_percent() {
  if [[ -n "$val" && -n "$max" && "$max" -gt 0 ]]; then
    percent=$(( val * 100 / max ))
    index=$(( percent * 9 / 101 ))
    icons=(        )
    icon="${icons[$index]}"
  else
    percent=0
    icon=""
  fi
}

case "$1" in
  --status)
    get_icon_and_percent
    echo "{\"text\": \"$percent\", \"percent\": $percent, \"icon\": \"$icon\"}"
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

# Refresh current value and notify
val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)
get_icon_and_percent

notify-send "Keyboard Backlight" "$icon  $percent%"
