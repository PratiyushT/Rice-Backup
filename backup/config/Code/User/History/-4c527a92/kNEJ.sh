#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Lenovo Yoga Tablet Mode Control switch"
POLL_INTERVAL=2
DEBOUNCE_MS=150
DEBUG=false

DEVICE_NODE="${DEVICE_NODE:-}"

on_tablet_mode() {
    $DEBUG && echo "[hook] Entered tablet mode"
    pkill -f "iio-hyprland eDP-1" 2>/dev/null || true
    MONITOR=eDP-1 iio-hyprland eDP-1 &
    echo $! > /tmp/iio-hyprland.pid
}

on_laptop_mode() {
    $DEBUG && echo "[hook] Returned to laptop mode"
    if [[ -f /tmp/iio-hyprland.pid ]]; then
        kill "$(cat /tmp/iio-hyprland.pid)" 2>/dev/null || true
        rm -f /tmp/iio-hyprland.pid
    fi
    hyprctl reload
}

find_event_node() {
    if [[ -n "$DEVICE_NODE" && -e "$DEVICE_NODE" ]]; then
        echo "$DEVICE_NODE"; return
    fi
    awk -v target="$DEVICE_NAME" '
        BEGIN { RS=""; FS="\n" }
        {
            ok=0; h="";
            for (i=1;i<=NF;i++) {
                if ($i ~ /^N: Name=/ && $i ~ "Name=\"" target "\"") ok=1
                if ($i ~ /^H: Handlers=/) h=$i
            }
            if (ok && h!="") {
                match(h, /event[0-9]+/)
                if (RSTART) { print "/dev/input/" substr(h, RSTART, RLENGTH); exit }
            }
        }
    ' /proc/bus/input/devices
}

sysfs_state() {
    local p v
    for p in \
        /sys/class/switch/tablet-mode/state \
        /sys/devices/platform/thinkpad_acpi/hotkey_tablet_mode \
        /sys/bus/platform/devices/ideapad_acpi/*/tablet_mode \
        /sys/bus/platform/devices/ideapad_acpi/*/switch
    do
        if [[ -r "$p" ]]; then
            v="$(tr -cd '0-9' < "$p" || true)"
            [[ "$v" == "1" ]] && { echo 1; return; }
            [[ "$v" == "0" ]] && { echo 0; return; }
        fi
    done
    echo ""
}

evtest_state() {
    local node="$1"
    if evtest --query "$node" EV_SW SW_TABLET_MODE >/dev/null 2>&1; then
        echo 1
    else
        echo 0
    fi
}

read_state() {
    local node="$1"
    local s
    s="$(sysfs_state)"
    if [[ "$s" == "1" || "$s" == "0" ]]; then
        echo "$s"
    else
        echo "$(evtest_state "$node")"
    fi
}

stable_state() {
    local node="$1"
    local last="" count=0
    while true; do
        local s
        s="$(read_state "$node")"
        if [[ "$s" == "$last" && -n "$s" ]]; then
            ((count++))
            if (( count >= 3 )); then
                echo "$s"
                return
            fi
        else
            last="$s"
            count=1
        fi
        sleep 0.2
    done
}

now_ms() { date +%s%3N; }

if [[ "${1:-}" == "-d" ]]; then
    DEBUG=true
fi

main_loop() {
    local node current last_change_ms

    while true; do
        node="$(find_event_node || true)"
        if [[ -z "$node" || ! -e "$node" ]]; then
            $DEBUG && echo "[warn] Device not found. Retrying in ${POLL_INTERVAL}s..."
            sleep "$POLL_INTERVAL"
            continue
        fi

        $DEBUG && echo "[info] Monitoring ${DEVICE_NAME} at ${node}"

        # Flush old events
        stdbuf -oL evtest "$node" | timeout 0.5 cat >/dev/null || true

        current="$(stable_state "$node")"
        $DEBUG && echo "[info] Initial mode: $([[ $current -eq 1 ]] && echo 'TABLET' || echo 'LAPTOP')]"
        last_change_ms="$(now_ms)"

        stdbuf -oL evtest "$node" 2>/dev/null | while IFS= read -r line; do
            if [[ "$line" =~ \(SW_TABLET_MODE\),\ value\ ([0-9]+) ]]; then
                local new="${BASH_REMATCH[1]}"
                local confirm
                confirm="$(sysfs_state)"
                if [[ "$confirm" == "1" || "$confirm" == "0" ]]; then
                    new="$confirm"
                fi

                local now
                now="$(now_ms)"
                local delta=$(( now - last_change_ms ))

                if [[ "$new" != "$current" && $delta -ge $DEBOUNCE_MS ]]; then
                    current="$new"
                    last_change_ms="$now"
                    if [[ $current -eq 1 ]]; then
                        $DEBUG && echo "[event] -> TABLET mode"
                        on_tablet_mode
                    else
                        $DEBUG && echo "[event] -> LAPTOP mode"
                        on_laptop_mode
                    fi
                fi
            fi
        done

        # If evtest exits (device disappeared), loop and re-detect
        $DEBUG && echo "[warn] evtest exited, re-detecting device..."
        sleep 1
    done
}

main_loop
