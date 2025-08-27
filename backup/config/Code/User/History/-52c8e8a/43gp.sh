#!/usr/bin/env bash
set -euo pipefail

# === Settings ===
SRC="$HOME/.config"
DEST="$HOME/Rice"
LISTFILE="$DEST/backup-list.txt"
MAX_SIZE="+0 -size -95M"   # Only include files <95 MB

echo ">>> Backing up $SRC -> $DEST"

# Ensure destination exists
mkdir -p "$DEST"

# Clean old list
rm -f "$LISTFILE"

# Rsync copy (preserve perms, skip >95MB)
rsync -a \
  --max-size=95m \
  --exclude='*cache*/' \
  --exclude='Cache/' \
  --exclude='Caches/' \
  --exclude='__pycache__/' \
  --exclude='node_modules/' \
  --exclude='*.log' \
  --exclude='*.tmp' \
  --exclude='*.lock' \
  "$SRC/" "$DEST/"

# Build a simple list of copied files (relative to DEST)
(
  cd "$DEST"
  find . -type f -o -type d | sort
) > "$LISTFILE"

echo ">>> Done. List of copied files written to $LISTFILE"
