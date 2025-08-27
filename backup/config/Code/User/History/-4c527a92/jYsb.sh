#!/usr/bin/env bash
set -euo pipefail

# --- Constants ---
input_device_name="Lenovo Yoga Tablet Mode Control switch"
mode_name="SW_TABLET_MODE"          # informational only
display_name="eDP-1"
pid_file="/tmp/iio-hyprland.pid"

# You can override this via env var if your SW_TABLET_MODE code differs.
# On Linux it is 1 for SW_TABLET_MODE.
sw_tablet_mode_code="${SW_TABLET_MODE_CODE:-1}"

# Size of struct input_event on 64-bit kernels:
#   struct timeval { long tv_sec; long tv_usec; } 16 bytes
#   type (u16), code (u16), value (s32)           8 bytes
#   Total                                         24 bytes
INPUT_EVENT_SIZE=24

# --- Functions ---
get_event_name() {
    # Return the event node (e.g., event8) for the device name
    grep -l "$input_device_name" /sys/class/input/event*/device/name \
      | sed 's|.*/\(event[0-9]\+\)/device/name|\1|' \
      | head -n1
}

start_rotation() {
    # Start iio-hyprland if not already running
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

# Lightweight listener that reads raw input_event records from /dev/input/eventX
listen_tablet_mode() {
    local file_name="$1"
    local dev="/dev/input/$file_name"

    # Open the device for binary reads on FD 3
    exec 3<"$dev" || { echo "[error] Cannot open $dev"; exit 1; }

    # Optional: stop any stray rotation process at start
    stop_rotation

    # We do not have a portable way in pure Bash to query the initial switch state
    # without ioctl. The first matching event will establish state and control rotation.

    local prev=""
    while :; do
        # Read one input_event (24 bytes) atomically
        # read -N reads raw bytes, stores into $data
        IFS= read -r -N "$INPUT_EVENT_SIZE" data <&3 || break

        # Extract fields:
        # type:  offset 16, 2 bytes, unsigned short
        # code:  offset 18, 2 bytes, unsigned short
        # value: offset 20, 4 bytes, signed 32
        # Use od on the in-memory chunk only (fast enough and much lighter than evtest)
        local type code value
        type="$(printf '%s' "$data" | od -An -t u2 -j16 -N2)"
        code="$(printf '%s' "$data" | od -An -t u2 -j18 -N2)"
        value="$(printf '%s' "$data" | od -An -t d4 -j20 -N4)"

        # Normalize trimming spaces
        type="${type//[[:space:]]/}"
        code="${code//[[:space:]]/}"
        value="${value//[[:space:]]/}"

        # 5 is EV_SW, match our SW_TABLET_MODE code
        if [[ "$type" == "5" && "$code" == "$sw_tablet_mode_code" ]]; then
            # value is 0 or 1 for SW_TABLET_MODE
            echo "tablet mode = $value"
            if [[ "$value" == "$prev" ]]; then
                continue
            fi
            prev="$value"
            if [[ "$value" == "1" ]]; then
                start_rotation
            else
                stop_rotation
            fi
        fi
    done

    # Clean up if device stream ends
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
