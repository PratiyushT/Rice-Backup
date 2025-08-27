#!/usr/bin/env bash
# fix-hid-dongles.sh
# Keep external USB HID receivers (2.4 GHz keyboard/mouse dongles) out of autosuspend on Linux.
# Also works for wired USB HID keyboards/mice if desired. Safe to apply to all USB HID keyboard/mouse devices.
# It installs a generic udev rule based on ID_USB_INTERFACES matching HID boot keyboard/mouse
# and applies the setting immediately to currently attached matching devices.

set -euo pipefail

RULE_PATH="/etc/udev/rules.d/99-hid-dongles-nosuspend.rules"

usage() {
  cat <<'USAGE'
Usage:
  sudo ./fix-hid-dongles.sh install   # Install persistent udev rule and apply now
  sudo ./fix-hid-dongles.sh remove    # Remove rule and revert to autosuspend=auto for matches
  sudo ./fix-hid-dongles.sh apply     # Apply "power/control=on" now for currently plugged matching devices

Notes:
- “Matching devices” are USB devices that expose a HID Boot Keyboard (0301) or HID Boot Mouse (0302) interface.
- This covers common 2.4 GHz receivers from Keychron, Logitech, Razer, etc., as well as wired USB HID boards.
USAGE
}

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Please run as root: sudo $0 <install|remove|apply>" >&2
    exit 1
  fi
}

write_rule() {
  echo "Writing udev rule to ${RULE_PATH}"
  install -m 0644 /dev/null "${RULE_PATH}"
  cat > "${RULE_PATH}" <<'RULE'
# Keep USB HID Boot Keyboard/Mouse receivers out of autosuspend.
# Matches any USB device whose ID_USB_INTERFACES indicates HID Boot Keyboard (0301) or HID Boot Mouse (0302).
# This catches most 2.4 GHz dongles and wired USB HID devices.
ACTION=="add|bind", SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:0301??:*", TEST=="power/control", ATTR{power/control}="on"
ACTION=="add|bind", SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:0302??:*", TEST=="power/control", ATTR{power/control}="on"
RULE
  udevadm control --reload
  udevadm trigger
  echo "Rule installed and udev reloaded."
}

remove_rule() {
  if [[ -f "${RULE_PATH}" ]]; then
    echo "Removing ${RULE_PATH}"
    rm -f "${RULE_PATH}"
    udevadm control --reload
    udevadm trigger
    echo "Rule removed and udev reloaded."
  else
    echo "No rule found at ${RULE_PATH}"
  fi
}

apply_now() {
  # Set power/control=on for currently attached matching devices.
  # We detect matches via udev properties on each USB device node.
  local did_any=0
  for d in /sys/bus/usb/devices/*; do
    [[ -f "$d/idVendor" && -f "$d/idProduct" ]] || continue
    # Query udev properties for this device
    if udevadm info -q property -p "$d" | grep -Eq 'ID_USB_INTERFACES=.*0301..|ID_USB_INTERFACES=.*0302..'; then
      if [[ -w "$d/power/control" ]]; then
        echo on > "$d/power/control" || true
        printf "Applied: %s -> " "$(basename "$d")"
        cat "$d/power/control"
        did_any=1
      fi
    fi
  done
  if [[ "$did_any" -eq 0 ]]; then
    echo "No matching USB HID receivers found now. Plug one in and re-run 'apply' if needed."
  fi
}

revert_now() {
  # Best-effort revert to autosuspend=auto for currently attached matching devices.
  local did_any=0
  for d in /sys/bus/usb/devices/*; do
    [[ -f "$d/idVendor" && -f "$d/idProduct" ]] || continue
    if udevadm info -q property -p "$d" | grep -Eq 'ID_USB_INTERFACES=.*0301..|ID_USB_INTERFACES=.*0302..'; then
      if [[ -w "$d/power/control" ]]; then
        echo auto > "$d/power/control" || true
        printf "Reverted: %s -> " "$(basename "$d")"
        cat "$d/power/control"
        did_any=1
      fi
    fi
  done
  if [[ "$did_any" -eq 0 ]]; then
    echo "No matching USB HID receivers found to revert."
  fi
}

main() {
  [[ $# -ge 1 ]] || { usage; exit 1; }
  case "$1" in
    install)
      need_root
      write_rule
      apply_now
      ;;
    remove)
      need_root
      remove_rule
      revert_now
      ;;
    apply)
      need_root
      apply_now
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
