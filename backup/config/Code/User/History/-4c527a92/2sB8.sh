#!/usr/bin/env bash
set -euo pipefail

# --- Constants ---
input_device_name="Lenovo Yoga Tablet Mode Control switch"
mode_name="SW_TABLET_MODE"
display_name="eDP-1"
pid_file="/tmp/iio-hyprland.pid"

# --- Functions ---
get_event_name() {
    # Return the event node (e.g., event8) for the device name
    grep -l "$input_device_name" /sys/class/input/event*/device/name \
      | sed 's|.*/\(event[0-9]\+\)/device/name|\1|' \
      | head -n1
}

start_rotation() {
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
            kill "$pid"
        fi
        rm -f "$pid_file"
    fi
}

create_event_cmd() {
    local file_name="$1"
    evtest "/dev/input/$file_name" | awk -v MODE="$mode_name" -v pidfile="$pid_file" -v disp="$display_name" '
        function start_rotation() {
            system("iio-hyprland " disp " & echo $! > " pidfile)
        }
        function stop_rotation() {
            pidcmd = "cat " pidfile " 2>/dev/null"
            pidcmd | getline pid
            close(pidcmd)
            if (pid != "") {
                system("kill " pid " 2>/dev/null; rm -f " pidfile)
            }
        }
        $0 ~ ("Event code [0-9]+ \\(" MODE "\\) state[[:space:]]+[0-9]+") {
            match($0, /state[[:space:]]+([0-9]+)/, m)
            if (m[1] != "") {
                print "tablet mode = " m[1]; fflush()
                if (m[1] == 1) start_rotation()
                else stop_rotation()
            }
        }
        $0 ~ ("code [0-9]+ \\(" MODE "\\), value[[:space:]]+[0-9]+") {
            match($0, /value[[:space:]]+([0-9]+)/, m)
            if (m[1] != "") {
                print "tablet mode = " m[1]; fflush()
                if (m[1] == 1) start_rotation()
                else stop_rotation()
            }
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
