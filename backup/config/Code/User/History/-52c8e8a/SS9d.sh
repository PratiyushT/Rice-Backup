#!/usr/bin/env bash
set -euo pipefail

# === Settings ===
SRC="$HOME/.config"
DEST="$HOME/Rice"
LISTFILE="$DEST/backup-list.txt"

# If $Script isn’t set in the environment, fall back to HyDE path
Script="${Script:-$HOME/.local/lib/hyde}"

echo ">>> Backing up $SRC -> $DEST"

# Ensure destination exists
mkdir -p "$DEST"

# Clean old list
rm -f "$LISTFILE"

# Rsync copy (preserve perms, skip >95MB, exclude unwanted patterns)
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
  --exclude='*.bkp' \
  --exclude='.git/' \
  --exclude='.gitignore' \
  "$SRC/" "$DEST/"

# Copy $Script/user separately into Rice/user
if [ -d "$Script/user" ]; then
  echo ">>> Copying $Script/user -> $DEST/user"
  rsync -a \
    --max-size=95m \
    --exclude='*.log' \
    --exclude='*.tmp' \
    --exclude='*.lock' \
    --exclude='*.bkp' \
    --exclude='.git/' \
    --exclude='.gitignore' \
    "$Script/user/" "$DEST/user/"
fi

# Build a simple list of copied files (relative to DEST)
(
  cd "$DEST"
  find . -type f -o -type d | sort
) > "$LISTFILE"

echo ">>> Done. List of copied files written to $LISTFILE"
