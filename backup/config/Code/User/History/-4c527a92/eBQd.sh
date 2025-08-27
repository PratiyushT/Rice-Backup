#!/usr/bin/env bash
set -euo pipefail

# --- Constants ---
input_device_name="Lenovo Yoga Tablet Mode Control switch"
mode_name="SW_TABLET_MODE"

# --- Functions ---
get_event_name() {
    # Finds the event file for the input device name
    grep -l "$input_device_name" /sys/class/input/event*/device/name \
        | sed 's|/sys/class/input/\(event[0-9]\+\)/device/name|\1|'
}

create_event_cmd() {
    local file_name="$1"
    # Runs evtest on the found event file, filtering only SW_TABLET_MODE state changes
    evtest "/dev/input/$file_name" | grep --line-buffered "$mode_name"
}

main() {
    local event_file
    event_file="$(get_event_name)"
    if [[ -z "$event_file" ]]; then
        echo "[error] Device '$input_device_name' not found."
        exit 1
    fi
    echo "[info] Monitoring '$input_device_name' on /dev/input/$event_file"
    create_event_cmd "$event_file"
}

main "$@"
