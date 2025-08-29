#!/usr/bin/env bash
# monitors-orientation-watch.sh
# Keeps Waybar outputs bound to current monitor orientations and hot-reloads safely.

set -uo pipefail

LOG_PREFIX="${LOG_PREFIX:-[mon-watch]}"
DEBOUNCE_MS="${DEBOUNCE_MS:-120}"
RETRY_SEC="${RETRY_SEC:-1}"       # wait before reconnecting the event stream
WAYBAR_CONFIG_OUT="${WAYBAR_CONFIG_OUT:-/home/PrT15/.config/waybar/config.jsonc}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "$LOG_PREFIX Missing dependency: $1" >&2; exit 1; }; }
need hyprctl
need jq
command -v stdbuf >/dev/null 2>&1 || true

declare -a PORTRAIT=()
declare -a LANDSCAPE=()
_prev_state="{}"

notify_err() {
  local msg="${1:-Unknown error}"
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "Waybar orientation watcher" "$msg" || true
  printf '%s %s\n' "$LOG_PREFIX" "$msg" >&2
}

arr_to_json() {
  if ((${#@})); then
    printf '%s\n' "$@" | jq -R . | jq -s .
  else
    jq -n '[]'
  fi
}

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
  readarray -t PORTRAIT  < <(jq -r 'to_entries | map(select(.value.orientation=="portrait")  | .key)[]?' <<<"$state_json")
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

update_waybar_config() {
  local target_dir="$(dirname "$WAYBAR_CONFIG_OUT")"
  local portrait_target="$target_dir/portrait.jsonc"
  local landscape_target="$target_dir/landscape.jsonc"
  local tmp_portrait tmp_landscape
  tmp_portrait="$(mktemp)" || { notify_err "mktemp portrait failed"; return 0; }
  tmp_landscape="$(mktemp)" || { notify_err "mktemp landscape failed"; return 0; }

  local p_json l_json
  p_json="$(arr_to_json "${PORTRAIT[@]}")"  || { notify_err "Failed to build PORTRAIT json"; rm -f "$tmp_portrait" "$tmp_landscape"; return 0; }
  l_json="$(arr_to_json "${LANDSCAPE[@]}")" || { notify_err "Failed to build LANDSCAPE json"; rm -f "$tmp_portrait" "$tmp_landscape"; return 0; }

  # Landscape bar
  if ! jq --argjson l "$l_json" '
      .output = $l
    ' >"$tmp_landscape" <<'JSON'
{
  "name": "landscape",
  "layer": "top",
  "output": ["*"],
  "position": "top",
  "mode": "dock",
  "height": 38,
  "exclusive": true,
  "passthrough": false,
  "reload_style_on_change": true,
  "include": [
    "$XDG_CONFIG_HOME/waybar/modules/*json*",
    "$XDG_CONFIG_HOME/waybar/includes/includes.json"
  ],
  "modules-left": [
    "group/pill#hyde-menu",
    "group/pill#system-info",
    "group/pill#clock",
    "group/pill#workspaces"
  ],
  "group/pill#hyde-menu": { "orientation": "inherit", "modules": ["custom/hyde-menu", "custom/updates"] },
  "group/pill#system-info": { "orientation": "inherit", "modules": ["cpu", "memory", "custom/sensorsinfo"] },
  "group/pill#clock": { "orientation": "inherit", "modules": ["clock"] },
  "group/pill#workspaces": { "orientation": "inherit", "modules": ["hyprland/workspaces"] },
  "modules-right": ["group/pill#tray", "group/pill#utils", "group/pill#power"],
  "group/pill#tray": { "orientation": "inherit", "modules": ["tray", "battery", "backlight", "pulseaudio", "pulseaudio#microphone"] },
  "group/pill#utils": { "orientation": "inherit", "modules": ["custom/cliphist", "idle_inhibitor", "custom/osk", "custom/autorotate-menu", "custom/display", "custom/battery-conservation"] },
  "group/pill#power": { "orientation": "inherit", "modules": ["custom/weather"] },
  "modules-center": ["group/pill#center"],
  "group/pill#center": { "orientation": "inherit", "modules": ["wlr/taskbar"] }
}
JSON
  then
    notify_err "jq failed to render landscape config."
    rm -f "$tmp_landscape"
  else
    mv -f "$tmp_landscape" "$landscape_target"
  fi

  # Portrait bar
  if ! jq --argjson p "$p_json" '
      .output = $p
    ' >"$tmp_portrait" <<'JSON'
{
  "name": "portrait",
  "layer": "top",
  "output": ["*"],
  "position": "top",
  "mode": "dock",
  "height": 38,
  "exclusive": true,
  "passthrough": false,
  "reload_style_on_change": true,
  "include": [
    "$XDG_CONFIG_HOME/waybar/modules/*json*",
    "$XDG_CONFIG_HOME/waybar/includes/includes.json"
  ],
  "modules-left": ["group/pill#hyde-menu", "group/pill#system-info", "group/pill#clock"],
  "group/pill#hyde-menu": { "orientation": "inherit", "modules": ["custom/hyde-menu","custom/updates"] },
  "group/pill#system-info": { "orientation": "inherit", "modules": ["custom/sensorsinfo"] },
  "group/pill#clock": { "orientation": "inherit", "modules": ["clock"] },
  "modules-right": ["group/pill#tray", "group/pill#utils", "group/pill#power"],
  "group/pill#tray": { "orientation": "inherit", "modules": ["tray", "battery", "backlight", "pulseaudio", "pulseaudio#microphone"] },
  "group/pill#utils": { "orientation": "inherit", "modules": ["custom/cliphist", "idle_inhibitor", "custom/osk", "custom/autorotate-menu", "custom/display", "custom/battery-conservation"] },
  "group/pill#power": { "orientation": "inherit", "modules": ["custom/weather"] },
  "modules-center": ["group/pill#center"],
  "group/pill#center": { "orientation": "inherit", "modules": ["wlr/taskbar"] }
}
JSON
  then
    notify_err "jq failed to render portrait config."
    rm -f "$tmp_portrait"
  else
    mv -f "$tmp_portrait" "$portrait_target"
  fi

  # Reload Waybar
  if ! pkill -SIGUSR2 waybar 2>/dev/null; then
    nohup waybar >/dev/null 2>&1 &
  fi

  printf '%s waybar configs updated -> %s, %s\n' "$LOG_PREFIX" "$portrait_target" "$landscape_target"
}

sleep_ms() {
  local ms="${1:-0}"
  python - <<PY 2>/dev/null || awk "BEGIN { system(\"sleep \" $ms/1000) }" >/dev/null 2>&1
import time
time.sleep(${ms}/1000.0)
PY
}

init_monitors() {
  local s
  s="$(snapshot_state)" || { notify_err "Failed to read monitors"; return 0; }
  printf '%s started. Initial state:\n' "$LOG_PREFIX"
  echo "$s" | jq .
  set_arrays_from_state "$s"
  print_arrays
  update_waybar_config
}

stream_events() {
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL hyprctl -w
  else
    hyprctl -w
  fi
}

watch_loop() {
  set +o pipefail
  trap '' PIPE

  while :; do
    echo "$LOG_PREFIX using hyprctl -w for events"
    while IFS= read -r _line; do
      ((DEBOUNCE_MS > 0)) && sleep_ms "$DEBOUNCE_MS"
      local curr
      curr="$(snapshot_state)" || { notify_err "hyprctl monitors failed"; continue; }
      if [[ "$curr" != "$_prev_state" ]]; then
        set_arrays_from_state "$curr"
        print_arrays
        update_waybar_config
      fi
    done < <(stream_events) || true

    sleep "$RETRY_SEC"
  done
}

main() {
  if ! pgrep -x waybar >/dev/null; then
    nohup waybar >/dev/null 2>&1 &
  fi
  init_monitors
  watch_loop
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main
fi
