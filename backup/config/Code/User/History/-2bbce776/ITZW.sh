#!/usr/bin/env bash
# Auto-rotate control using linuxflip in one file

TABLET_CMD='MONITOR=eDP-1 iio-hyprland eDP-1 &'
LAPTOP_CMD='pkill -f "iio-hyprland eDP-1" || true'

# Run linuxflip with tablet and laptop commands
linuxflip "$TABLET_CMD" "$LAPTOP_CMD"
