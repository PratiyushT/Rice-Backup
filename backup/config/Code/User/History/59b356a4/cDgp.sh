#!/usr/bin/env bash
set -euo pipefail

# Hard dependencies: curl, jq
CURL="/usr/bin/curl"
JQ="/usr/bin/jq"
[ -x "$CURL" ] || { echo "curl not found"; exit 1; }
[ -x "$JQ" ]   || { echo "jq not found"; exit 1; }

# Cache directory
OUT_DIR="/run/user/$UID/hyprlock"
CACHE_FILE="$OUT_DIR/weather.txt"
STAMP_FILE="$OUT_DIR/.weather_stamp"
LOCK_FILE="$OUT_DIR/.weather_lock"

# How long to cache the weather (seconds)
TTL="${TTL:-1800}"  # 30 minutes

mkdir -p "$OUT_DIR"

# If cache is fresh, print and exit
now=$(date +%s)
if [[ -f "$CACHE_FILE" && -f "$STAMP_FILE" ]]; then
  age=$(( now - $(cat "$STAMP_FILE" 2>/dev/null || echo 0) ))
  if (( age < TTL )); then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Acquire a simple lock (avoid thundering herd from multiple hyprlock calls)
exec 9>"$LOCK_FILE"
flock -n 9 || { [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE" && exit 0; }

# 1) Geolocate (ip-api.com)
UA="Hyprlock-Weather/1.0 (+https://wiki.hyprland.org)"
LOC_JSON="$($CURL -m 3 -sS -H "User-Agent: $UA" "http://ip-api.com/json/")" || LOC_JSON=""
CITY="$([[ -n "$LOC_JSON" ]] && echo "$LOC_JSON" | $JQ -r '.city // empty' || echo "")"
COUNTRY="$([[ -n "$LOC_JSON" ]] && echo "$LOC_JSON" | $JQ -r '.countryCode // empty' || echo "")"

# Fallback if geolocation failed
if [[ -z "$CITY" || -z "$COUNTRY" ]]; then
  # Optional: set your defaults here
  CITY="${CITY:-Dallas}"
  COUNTRY="${COUNTRY:-US}"
fi

# 2) Encode city for URL (spaces, commas, etc.)
urlencode() {
  local s="$1" i c out=""
  for (( i=0; i<${#s}; i++ )); do
    c=${s:$i:1}
    case "$c" in
      [a-zA-Z0-9._~-]) out+="$c" ;;
      *) printf -v out "%s%%%02X" "$out" "'$c" ;;
    esac
  done
  printf '%s' "$out"
}
CITY_ENC="$(urlencode "$CITY")"

# 3) Query wttr.in with timeouts and UA
# %c: weather symbol, %C: condition, %t: temp; add &u for US units (°F)
WEATHER="$($CURL -m 3 -sS -H "User-Agent: $UA" "https://wttr.in/${CITY_ENC}?format=%c+%C+%t&u" || true)"

# Validate and write cache
if [[ -n "$WEATHER" && "$WEATHER" != *"Unknown location"* ]]; then
  printf "%s, %s: %s\n" "$COUNTRY" "$CITY" "$WEATHER" | tee "$CACHE_FILE" >/dev/null
  echo "$now" > "$STAMP_FILE"
else
  # Keep the old cache if present, otherwise print a friendly message
  if [[ -f "$CACHE_FILE" ]]; then
    cat "$CACHE_FILE"
  else
    echo "Weather unavailable for ${COUNTRY:-??}, ${CITY:-??}"
  fi
fi
