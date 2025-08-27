#!/usr/bin/env bash
set -euo pipefail

# --- Constants (dynamic-friendly) ---
input_device_name="Lenovo Yoga Tablet Mode Control switch"
mode_name="SW_TABLET_MODE"

# --- Functions ---
get_event_name() {
    # Return the event node (e.g., event8) for the device name
    grep -l "$input_device_name" /sys/class/input/event*/device/name \
      | sed 's|.*/\(event[0-9]\+\)/device/name|\1|' \
      | head -n1
}

create_event_cmd() {
    local file_name="$1"
    # Run evtest and print only the tablet mode state/value lines as: "tablet mode = <0|1>"
    # Handles both the initial "state <n>" line and subsequent ", value <n>" lines.
    evtest "/dev/input/$file_name" | awk -v MODE="$mode_name" '
        $0 ~ ("Event code [0-9]+ \\(" MODE "\\) state[[:space:]]+[0-9]+") {
            match($0, /state[[:space:]]+([0-9]+)/, m);
            if (m[1] != "") { print "tablet mode = " m[1]; fflush(); }
        }
        $0 ~ ("code [0-9]+ \\(" MODE "\\), value[[:space:]]+[0-9]+") {
            match($0, /value[[:space:]]+([0-9]+)/, m);
            if (m[1] != "") { print "tablet mode = " m[1]; fflush(); }
        }
    '
}

main() {
    local event_file
    event_file="$(get_event_name || true)"
    if [[ -z "${event_file:-}" ]]; then
        echo "[error] Device '$input_device_name' not found."
        exit 1
    fi
    echo "[info] Monitoring '$input_device_name' on /dev/input/$event_file"
    create_event_cmd "$event_file"
}

main "$@"
