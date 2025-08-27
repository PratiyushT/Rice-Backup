#!/usr/bin/env bash
set -euo pipefail

NMCLI="/usr/bin/nmcli"

# 1) Read boolean from hyprlock.conf once, default to false
show_ssid="$(grep -oP '^\$wifi-mode\s*=\s*\K\S+' ~/.config/hypr/hyprlock.conf 2>/dev/null || true)"
[[ "$show_ssid" == "true" ]] || show_ssid=false

# 2) Fast path for Ethernet
if $NMCLI -t -f TYPE,STATE connection show --active 2>/dev/null | grep -q '^ethernet:activated$'; then
  echo "󰈀  Ethernet"
  exit 0
fi

# 3) Is Wi-Fi enabled and connected without rescanning
wifi_enabled="$($NMCLI -t -g WIFI general 2>/dev/null || echo disabled)"
if [[ "$wifi_enabled" != "enabled" ]]; then
  echo "󰤮  Wi-Fi Off"
  exit 0
fi

# Find the connected Wi-Fi device quickly
# Example line: "wlan0:wifi:connected"
wifi_dev="$($NMCLI -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')"
if [[ -z "${wifi_dev:-}" ]]; then
  echo "󰤮  No Wi-Fi"
  exit 0
fi

# 4) Get SSID and signal without forcing a rescan
# The current network is marked with '*' and SIGNAL is already a percentage
# Example line: "*:MySSID:67"
current="$($NMCLI -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: '$1=="*"{print $2":"$3; exit}')"
ssid="${current%%:*}"
signal="${current##*:}"

if [[ -z "${ssid:-}" || -z "${signal:-}" ]]; then
  echo "󰤮  No Wi-Fi"
  exit 0
fi

# 5) Choose icon by signal bucket
# 0–24, 25–49, 50–74, 75–99, 100
icons=( "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" )
# clamp 0..100
if (( signal < 0 )); then signal=0; fi
if (( signal > 100 )); then signal=100; fi
idx=$(( signal / 25 ))
icon="${icons[$idx]}"

# 6) Output
if [[ "$show_ssid" == "true" ]]; then
  printf "%s  %s\n" "$icon" "$ssid"
else
  printf "%s  Connected\n" "$icon"
fi
