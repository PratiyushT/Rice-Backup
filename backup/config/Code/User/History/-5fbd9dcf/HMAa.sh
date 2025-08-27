#!/usr/bin/env bash
set -euo pipefail

# monitors-orientation-watch.sh
# Maintains PORTRAIT=() and LANDSCAPE=() arrays for Hyprland monitors.
# Uses hyprctl -w for events, auto-reconnects if the stream ends.

LOG_PREFIX="${LOG_PREFIX:-[mon-watch]}"
DEBOUNCE_MS="${DEBOUNCE_MS:-120}"
RETRY_SEC="${RETRY_SEC:-1}" # wait before reconnecting the event stream

need() { command -v "$1" >/dev/null 2>&1 || {
  echo "$LOG_PREFIX Missing dependency: $1" >&2
  exit 1
}; }
need hyprctl
need jq
command -v stdbuf >/dev/null 2>&1 || true

declare -a PORTRAIT=()
declare -a LANDSCAPE=()
_prev_state="{}"

snapshot_state() {
  hyprctl monitors -j 2>/dev/null | jq -rc '
    map({
      key: .name,
      value: {
        transform: (.transform // 0),
        orientation: (
          if ((.transform==1) or (.transform==3) or (.transform==5) or (.transform==7) or (.width < .height))
          then "portrait" else "landscape" end
        ),
        size: "\(.width)x\(.height)"
      }
    }) | from_entries
  '
}

set_arrays_from_state() {
  local state_json="$1"
  readarray -t PORTRAIT < <(jq -r 'to_entries | map(select(.value.orientation=="portrait")  | .key)[]?' <<<"$state_json")
  readarray -t LANDSCAPE < <(jq -r 'to_entries | map(select(.value.orientation=="landscape") | .key)[]?' <<<"$state_json")
  _prev_state="$state_json"
}

print_arrays() {
  printf 'PORTRAIT=('
  ((${#PORTRAIT[@]})) && printf '"%s" ' "${PORTRAIT[@]}"
  printf ') ; LANDSCAPE=('
  ((${#LANDSCAPE[@]})) && printf '"%s" ' "${LANDSCAPE[@]}"
  printf ')\n'
}

# ===== Waybar config updater =====
# Generates a Waybar config with two bars:
#   [0] "landscape" bar -> bound to LANDSCAPE outputs
#   [1] "portrait"  bar -> bound to PORTRAIT outputs
# Writes to $WAYBAR_CONFIG_OUT or ~/.config/waybar/config.orient.json
# Sends SIGUSR2 to Waybar to live-reload.
update_waybar_config() {
  local target="${WAYBAR_CONFIG_OUT:-/home/PrT15/.config/waybar/config.jsonc}"

  # Convert Bash arrays -> JSON arrays safely
  local p_json l_json
  p_json="$(printf '%s\n' "${PORTRAIT[@]}" | jq -R . | jq -s .)"
  l_json="$(printf '%s\n' "${LANDSCAPE[@]}" | jq -R . | jq -s .)"

  # Base template from your message. Only the "output" arrays are updated here.
  # If you want to tweak modules later, edit the JSON below.
  jq --argjson p "$p_json" --argjson l "$l_json" '
    .[0].output = $l
    | .[1].output = $p
  ' >"$target" <<'JSON'
[
  {
    "name": "landscape",
    "layer": "top",
    "output": [
      "*"
    ],
    "position": "top",
    "mode": "dock",
    "height": 10,
    "exclusive": true,
    "passthrough": false,
    "reload_style_on_change": true,
    "include": [
      "$XDG_CONFIG_HOME/waybar/modules/*json*",
      "$XDG_CONFIG_HOME/waybar/includes/includes.json"
    ],
    "modules-left": [
      "group/pill#left1",
      "group/pill#left2",
      "group/pill#left3"
    ],
    "group/pill#left1": {
      "orientation": "inherit",
      "modules": [
        "cpu",
        "memory",
        "custom/cpuinfo",
        "custom/gpuinfo"
      ]
    },
    "group/pill#left2": {
      "orientation": "inherit",
      "modules": [
        "idle_inhibitor",
        "clock"
      ]
    },
    "group/pill#left3": {
      "orientation": "inherit",
      "modules": [
        "hyprland/workspaces"
      ]
    },
    "modules-right": [
      "group/pill#right1",
      "group/pill#right2",
      "group/pill#right3"
    ],
    "group/pill#right1": {
      "orientation": "inherit",
      "modules": [
        "privacy",
        "tray",
        "custom/cliphist"
      ]
    },
    "group/pill#right2": {
      "orientation": "inherit",
      "modules": [
        "backlight",
        "network",
        "pulseaudio",
        "pulseaudio#microphone",
        "custom/updates",
        "custom/keybindhint"
      ]
    },
     "group/pill#right3": {
      "orientation": "inherit",
      "modules": [
        "battery",
        "custom/battery-conservation",
        "custom/hyde-menu",
        "custom/autorotate-menu",
        "custom/power"
      ]
    },
    "modules-center": [
      "group/pill#center"
    ],
    "group/pill#center": {
      "orientation": "inherit",
      "modules": [
        "wlr/taskbar"
      ]
    }
  },
  {
    "name": "portrait",
    "layer": "top",
    "output": [
      "*"
    ],
    "position": "top",
    "mode": "dock",
    "height": 10,
    "exclusive": true,
    "passthrough": false,
    "reload_style_on_change": true,
    "include": [
      "$XDG_CONFIG_HOME/waybar/modules/*json*",
      "$XDG_CONFIG_HOME/waybar/includes/includes.json"
    ],
    "modules-left": [
      "group/pill#left1",
      "group/pill#left2"
    ],
    "group/pill#left1": {
      "orientation": "inherit",
      "modules": [
        "custom/cpuinfo",
        "custom/gpuinfo"
      ]
    },
    "group/pill#left2": {
      "orientation": "inherit",
      "modules": [
        "idle_inhibitor",
        "clock"
      ]
    },
    "modules-right": [
      "group/pill#right1",
      "group/pill#right2",
      "group/pill#right3"
    ],
    "group/pill#right1": {
      "orientation": "inherit",
      "modules": [
        "privacy",
        "tray",
        "custom/cliphist"
      ]
    },
    "group/pill#right2": {
      "orientation": "inherit",
      "modules": [
        "backlight",
        "network",
        "pulseaudio",
        "pulseaudio#microphone",
        "custom/updates",
        "custom/keybindhint"
      ]
    },
     "group/pill#right3": {
      "orientation": "inherit",
      "modules": [
        "battery",
        "custom/battery-conservation",
        "custom/hyde-menu",
        "custom/autorotate-menu",
        "custom/power"
      ]
    },
    "modules-center": [
      "group/pill#center"
    ],
    "group/pill#center": {
      "orientation": "inherit",
      "modules": [
        "wlr/taskbar"
      ]
    }
  }
]

JSON
  # Reload Waybar to pick up the new assignments
  pkill -SIGUSR2 waybar 2>/dev/null || true
  printf '%s waybar config updated -> %s\n' "$LOG_PREFIX" "$target"
}

sleep_ms() {
  # portable millisecond sleep
  local ms="${1:-0}"
  python - <<PY 2>/dev/null || awk "BEGIN { system(\"sleep \" $ms/1000) }" >/dev/null 2>&1
import time
time.sleep(${ms}/1000.0)
PY
}

init_monitors() {
  local s
  s="$(snapshot_state)"
  printf '%s started. Initial state:\n' "$LOG_PREFIX"
  echo "$s" | jq .
  set_arrays_from_state "$s"
  print_arrays
  update_waybar_config
}

stream_events() {
  # Yields Hyprland events line-by-line, line buffered if stdbuf exists
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL hyprctl -w
  else
    hyprctl -w
  fi
}

watch_loop() {
  # Disable pipefail semantics around the event stream to avoid quitting on reader exit
  set +o pipefail
  trap '' PIPE

  while :; do
    echo "$LOG_PREFIX using hyprctl -w for events"
    # Use process substitution so the while loop runs in the current shell
    while IFS= read -r _line; do
      ((DEBOUNCE_MS > 0)) && sleep_ms "$DEBOUNCE_MS"
      local curr
      curr="$(snapshot_state)"
      if [[ "$curr" != "$_prev_state" ]]; then
        set_arrays_from_state "$curr"
        print_arrays
        update_waybar_config
      fi
    done < <(stream_events)

    echo "$LOG_PREFIX event stream ended. Reconnecting in ${RETRY_SEC}s..."
    sleep "$RETRY_SEC"
  done
}

main() {
  pkill -x waybar || true
  waybar &
  disown

  init_monitors
  watch_loop
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main
fi
