#!/usr/bin/env bash
set -euo pipefail

NMCLI="/usr/bin/nmcli"
config_file="$HOME/.config/hypr/hyprlock.conf"

# Read $wifi-mode safely; default to false if missing/unreadable
wifi_mode="$(sed -n 's/^[[:space:]]*\$wifi-mode[[:space:]]*=[[:space:]]*\(true\|false\).*/\1/p' "$config_file" 2>/dev/null | head -n1)"
wifi_mode="${wifi_mode:-false}"

# 1) Ethernet check
if $NMCLI -t -f TYPE,STATE connection show --active 2>/dev/null | grep -q '^ethernet:activated$'; then
  echo "󰈀  Ethernet"
  exit 0
fi

# 2) Wi-Fi enabled?
wifi_enabled="$($NMCLI -t -g WIFI general 2>/dev/null || echo disabled)"
if [[ "$wifi_enabled" != "enabled" ]]; then
  echo "󰤮  Wi-Fi Off"
  exit 0
fi

# 3) Connected Wi-Fi device
wifi_dev="$($NMCLI -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')"
if [[ -z "${wifi_dev:-}" ]]; then
  echo "󰤮  No Wi-Fi"
  exit 0
fi

# 4) SSID + signal (no rescan)
current="$($NMCLI -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: '$1=="*"{print $2":"$3; exit}')"
ssid="${current%%:*}"
signal="${current##*:}"

# Fallbacks
[[ -z "${signal:-}" ]] && signal=0

# If wifi-mode=false, always show generic "Connected"
# If wifi-mode=true, show SSID (with truncation). If SSID missing, fall back to "Connected".
if [[ "$wifi_mode" == "true" ]]; then
  if [[ -z "${ssid:-}" ]]; then
    ssid="Connected"
  else
    # truncate SSID to 8 chars with ellipsis
    if (( ${#ssid} > 8 )); then
      ssid="${ssid:0:8}..."
    fi
  fi
else
  ssid="Connected"
fi

# 5) Pick signal icon
icons=( "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" )
(( signal < 0 )) && signal=0
(( signal > 100 )) && signal=100
idx=$(( signal / 25 ))
icon="${icons[$idx]}"

# 6) Final output
printf "%s  %s\n" "$icon" "$ssid"
