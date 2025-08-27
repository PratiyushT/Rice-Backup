#!/usr/bin/env bash
set -euo pipefail

# ========= Settings =========
SRC="$HOME/.config"
DEST="$HOME/Rice/backup"
LISTFILE="$HOME/Rice/backup-list.txt"
MAX_SIZE=95m
CLEAN_PREVIOUS="${CLEAN_PREVIOUS:-true}"

# Your script root; supports either $SCRIPT or $Script, defaults to HyDE path
SCRIPT_ROOT="${SCRIPT:-${Script:-$HOME/.local/lib/hyde}}"

# Set to "true" to pick folders interactively with fzf (optional)
USE_FZF="${USE_FZF:-false}"

# ========= Whitelist of folders under ~/.config =========
# Edit this list to match the folders you showed in your screenshot.
# Use exact directory names as they appear under ~/.config (relative paths allowed).
ALLOW_DIRS=(
  "Code - OSS/User"
  "Code/User"
  "VSCodium/User"

  "dunst"
  "fastfetch"
  "gtk-3.0"
  "hyde"
  "hypr"
  "kitty"
  "lf"
  "nvim"
  "mpv"
  "swaylock"
  "swaync"
  "waybar"
  "zsh"
)

# ========= Exclude patterns (applied to rsync) =========
EXCLUDES=(
  "--exclude=.git/"
  "--exclude=.gitignore"
  "--exclude=.config.bkp/"

  "--exclude=*cache*/"
  "--exclude=Cache/"
  "--exclude=Caches/"
  "--exclude=GPUCache/"
  "--exclude=__pycache__/"
  "--exclude=node_modules/"
  "--exclude=*.tmp"
  "--exclude=*.lock"
  "--exclude=*.log"
  "--exclude=*.bkp"

  "--exclude=Code - OSS/Code Cache/"
  "--exclude=Code - OSS/CachedData/"
  "--exclude=Code - OSS/CachedProfilesData/"
  "--exclude=Code - OSS/GPUCache/"
  "--exclude=Code - OSS/Crashpad/"
  "--exclude=Code - OSS/logs/"
  "--exclude=Code - OSS/Local Storage/"
  "--exclude=Code - OSS/Service Worker/"
  "--exclude=Code - OSS/WebStorage/"
  "--exclude=Code - OSS/blob_storage/"
  "--exclude=Code - OSS/SharedStorage/"
  "--exclude=Code - OSS/DawnWebGPUCache/"
  "--exclude=Code - OSS/DawnGraphiteCache/"
  "--exclude=Code - OSS/User/workspaceStorage/"
  "--exclude=Code - OSS/User/globalStorage/state.vscdb*"

  "--exclude=*/Service Worker/"
  "--exclude=*/Code Cache/"
  "--exclude=*/WebStorage/"
  "--exclude=*/Crashpad/"
  "--exclude=*/GPUCache/"
  "--exclude=*/Local Storage/"

  "--exclude=*/leveldb/"
  "--exclude=*/IndexedDB/"
  "--exclude=*/databases/"

  "--exclude=.DS_Store"
  "--exclude=Thumbs.db"
)

# ========= Helpers =========
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }

rsync_copy_dir () {
  local from_dir="$1" rel="$2" dest_dir="$3"
  rsync -a --human-readable --max-size="${MAX_SIZE}" --prune-empty-dirs \
    "${EXCLUDES[@]}" \
    "${from_dir%/}/" "${dest_dir%/}/${rel%/}/"
}

scrub_dest () {
  local root="$1"
  # delete large files and junk patterns already present
  find "$root" -type f -size +95M -delete 2>/dev/null || true
  find "$root" -type d \( -name .git -o -name '*cache*' -o -name Cache -o -name Caches -o \
    -name GPUCache -o -name '__pycache__' -o -name node_modules -o \
    -name 'Service Worker' -o -name 'Code Cache' -o -name WebStorage -o \
    -name Crashpad -o -name 'Local Storage' -o -name leveldb -o -name IndexedDB -o \
    -name databases -o -name '.config.bkp' \) -prune -exec rm -rf {} + 2>/dev/null || true
  find "$root" -type f \( -name '*.tmp' -o -name '*.lock' -o -name '*.log' -o -name '*.bkp' \
    -o -name '.gitignore' -o -name '.DS_Store' -o -name 'Thumbs.db' \) \
    -delete 2>/dev/null || true
}

pick_with_fzf () {
  need fzf
  # Present directories in ~/.config, allow multi-select
  mapfile -t ALLOW_DIRS < <(find "$SRC" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
    | sort | fzf --multi --prompt="Select folders to back up: " --height=80%)
}

# ========= Run =========
need rsync

if [[ "$USE_FZF" == "true" ]]; then
  pick_with_fzf
fi

# Filter to only those that actually exist
declare -a FINAL_DIRS=()
for d in "${ALLOW_DIRS[@]}"; do
  [[ -d "$SRC/$d" ]] && FINAL_DIRS+=("$d")
done

echo ">>> Preparing destination: $DEST"
mkdir -p "$DEST"

if [[ "$CLEAN_PREVIOUS" == "true" ]]; then
  echo ">>> Scrubbing old junk from destination"
  scrub_dest "$DEST"
fi

# Copy only whitelisted dirs
for rel in "${FINAL_DIRS[@]}"; do
  echo ">>> Syncing $SRC/$rel -> $DEST/$rel"
  rsync_copy_dir "$SRC/$rel" "$rel" "$DEST"
done

# Copy $SCRIPT/$Script -> script
if [[ -d "$SCRIPT_ROOT" ]]; then
  echo ">>> Syncing $SCRIPT_ROOT -> $DEST/script"
  rsync -a --human-readable --max-size="${MAX_SIZE}" --prune-empty-dirs \
    "${EXCLUDES[@]}" \
    "${SCRIPT_ROOT%/}/" "${DEST%/}/script/"
fi

# Build the simple list of what’s in DEST now
echo ">>> Writing $LISTFILE"
mkdir -p "$(dirname "$LISTFILE")"
(
  cd "$DEST"
  find . -type d -o -type f | sort
) > "$LISTFILE"

echo ">>> Done."
echo "Backed up folders:"
printf ' - %s\n' "${FINAL_DIRS[@]}"
echo "List saved to $LISTFILE"
