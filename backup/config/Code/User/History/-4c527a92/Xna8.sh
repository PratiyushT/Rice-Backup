#!/usr/bin/env bash
set -euo pipefail

# --- Constants ---
input_device_name="Lenovo Yoga Tablet Mode Control switch"
mode_name="SW_TABLET_MODE"          # informational only
display_name="eDP-1"
pid_file="/tmp/iio-hyprland.pid"

# SW_TABLET_MODE code (usually 1)
sw_tablet_mode_code="${SW_TABLET_MODE_CODE:-1}"

# struct input_event size for 64-bit kernel
INPUT_EVENT_SIZE=24

# --- Functions ---
get_event_name() {
    grep -l "$input_device_name" /sys/class/input/event*/device/name \
      | sed 's|.*/\(event[0-9]\+\)/device/name|\1|' \
      | head -n1
}

start_rotation() {
    if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        return
    fi
    echo "[info] Starting auto-rotation..."
    iio-hyprland "$display_name" &
    echo $! > "$pid_file"
}

stop_rotation() {
    if [[ -f "$pid_file" ]]; then
        local pid
        pid="$(cat "$pid_file")"
        if kill -0 "$pid" 2>/dev/null; then
            echo "[info] Stopping auto-rotation..."
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$pid_file"
    fi
}

listen_tablet_mode() {
    local file_name="$1"
    local dev="/dev/input/$file_name"

    exec 3<"$dev" || { echo "[error] Cannot open $dev"; exit 1; }
    stop_rotation

    local prev=""
    while :; do
        IFS= read -r -N "$INPUT_EVENT_SIZE" data <&3 || break

        local type code value
        type="$(printf '%s' "$data" | od -An -t u2 -j16 -N2)"
        code="$(printf '%s' "$data" | od -An -t u2 -j18 -N2)"
        value="$(printf '%s' "$data" | od -An -t d4 -j20 -N4)"

        type="${type//[[:space:]]/}"
        code="${code//[[:space:]]/}"
        value="${value//[[:space:]]/}"

        if [[ "$type" == "5" && "$code" == "$sw_tablet_mode_code" ]]; then
            echo "tablet mode = $value"
            [[ "$value" == "$prev" ]] && continue
            prev="$value"
            if [[ "$value" == "1" ]]; then
                start_rotation
            else
                stop_rotation
            fi
        fi
    done

    stop_rotation
    exec 3<&-
}

main() {
    local event_file
    event_file="$(get_event_name || true)"
    if [[ -z "${event_file:-}" ]]; then
        echo "[error] Device '$input_device_name' not found."
        exit 1
    fi
    echo "[info] Monitoring '$input_device_name' on /dev/input/$event_file"
    listen_tablet_mode "$event_file"
}

main "$@"
