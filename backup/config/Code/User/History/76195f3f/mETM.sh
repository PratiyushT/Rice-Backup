#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"

DEVICE="platform::kbd_backlight"

# Check if SwayOSD is installed
use_swayosd=false
isNotify=${BRIGHTNESS_NOTIFY:-true}
if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
    use_swayosd=true
fi

get_icon() {
    local percent=$1
    local icons=("" "" "" "" "" "" "" "" "")
    local index=$((percent / 12))
    [[ $index -ge ${#icons[@]} ]] && index=$((${#icons[@]} - 1))
    echo "${icons[$index]}"
}

print_error() {
    local cmd
    cmd=$(basename "$0")
    cat <<EOF
    "${cmd}" <action> [step]
    ...valid actions are...
        i -- <i>ncrease keyboard backlight [+1]
        d -- <d>ecrease keyboard backlight [-1]
        --status -- print JSON for Waybar

    Example:
        "${cmd}" i
        "${cmd}" d
        "${cmd}" --status
EOF
}

send_notification() {
    val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)
    max=$(brightnessctl -d "$DEVICE" max 2>/dev/null)
    percent=$(( (val * 100 + (max / 2)) / max ))
    angle="$(( ((percent + 2) / 5) * 5 ))"
    ico="${iconsDir}/Wallbash-Icon/media/knob-${angle}.svg"
    bar=$(seq -s "." $((percent / 15)) | sed 's/[0-9]//g')
    [[ "${isNotify}" == true ]] && notify-send -a "HyDE Notify" -r 9 -t 800 -i "${ico}" "${percent}${bar}" "kbd_backlight"
}

get_status_json() {
    val=$(brightnessctl -d "$DEVICE" get 2>/dev/null)
    max=$(brightnessctl -d "$DEVICE" max 2>/dev/null)

    if [[ -z "$val" || -z "$max" || "$max" -eq 0 ]]; then
        echo '{"text": "N/A", "percent": 0, "icon": ""}'
        exit 0
    fi

    percent=$(( (val * 100 + (max / 2)) / max ))
    icon=$(get_icon "$percent")
    echo "{\"text\": \"${percent}%\", \"percent\": ${percent}, \"icon\": \"${icon}\"}"
}

step=1

case $1 in
    i | -i)
        $use_swayosd && swayosd-client --brightness raise "$step" && exit 0
        brightnessctl -d "$DEVICE" set +"${step}" >/dev/null
        send_notification
        ;;
    d | -d)
        $use_swayosd && swayosd-client --brightness lower "$step" && exit 0
        brightnessctl -d "$DEVICE" set "${step}"- >/dev/null
        send_notification
        ;;
    --status)
        get_status_json
        ;;
    *)
        print_error
        ;;
esac
