#!/usr/bin/env bash
set -euo pipefail

NMCLI="/usr/bin/nmcli"

# 1) Fast path for Ethernet
if $NMCLI -t -f TYPE,STATE connection show --active 2>/dev/null | grep -q '^ethernet:activated$'; then
  echo "󰈀  Ethernet"
  exit 0
fi

# 2) Is Wi-Fi enabled?
wifi_enabled="$($NMCLI -t -g WIFI general 2>/dev/null || echo disabled)"
if [[ "$wifi_enabled" != "enabled" ]]; then
  echo "󰤮  Wi-Fi Off"
  exit 0
fi

# 3) Find connected Wi-Fi device
wifi_dev="$($NMCLI -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')"
if [[ -z "${wifi_dev:-}" ]]; then
  echo "󰤮  No Wi-Fi"
  exit 0
fi

# 4) Get SSID and signal (no rescan)
current="$($NMCLI -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: '$1=="*"{print $2":"$3; exit}')"
ssid="${current%%:*}"
signal="${current##*:}"

if [[ -z "${ssid:-}" || -z "${signal:-}" ]]; then
  echo "󰤮  No Wi-Fi"
  exit 0
fi

# 5) Wi-Fi signal icon
icons=( "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" )
(( signal < 0 )) && signal=0
(( signal > 100 )) && signal=100
idx=$(( signal / 25 ))
icon="${icons[$idx]}"

# 6) Always show SSID
printf "%s  %s\n" "$icon" "$ssid"
