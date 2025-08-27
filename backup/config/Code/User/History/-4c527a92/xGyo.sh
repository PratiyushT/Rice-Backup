on_tablet_mode() {
  echo "[hook] Entered tablet mode"
  # Start iio-hyprland rotation (example monitor eDP-1)
  MONITOR=eDP-1 iio-hyprland eDP-1 &
  echo $! > /tmp/iio-hyprland.pid
}

on_laptop_mode() {
  echo "[hook] Returned to laptop mode"
  # Stop rotation
  if [[ -f /tmp/iio-hyprland.pid ]]; then
    kill "$(cat /tmp/iio-hyprland.pid)" 2>/dev/null || true
    rm -f /tmp/iio-hyprland.pid
  fi
  # Restore original monitor settings
  hyprctl reload   # or hyprctl keyword monitor "eDP-1,2880x1800@90,0x0,1"
}
