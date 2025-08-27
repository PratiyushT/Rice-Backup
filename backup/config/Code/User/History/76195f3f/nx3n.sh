#!/usr/bin/env bash

DEVICE="platform::kbd_backlight"

max=$(brightnessctl -d "$DEVICE" max 2>/dev/null)
val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)

get_icon_and_percent() {
  case "$val" in
    0)
      percent="OFF"
      icon=""
      ;;
    1)
      percent="MED"
      icon=""
      ;;
    2)
      percent="HIGH"
      icon=""
      ;;
    *)
      percent="N/A"
      icon=""
      ;;
  esac
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
