#!/usr/bin/env bash
set -euo pipefail

# ========= Settings =========
BACKUP="$HOME/Rice/backup"

SRC_CONFIG="$BACKUP/config"
SRC_SCRIPT="$BACKUP/script"

# new: local-share sources
SRC_LOCAL="$BACKUP/local"
SRC_HYPR_SHARE="$SRC_LOCAL/hypr"
SRC_HYDE_SHARE="$SRC_LOCAL/hyde"

DEST_CONFIG="$HOME/.config"
DEST_SCRIPT="$HOME/.local/lib/hyde"

# new: local-share destinations
DEST_HYPR_SHARE="$HOME/.local/share/hypr"
DEST_HYDE_SHARE="$HOME/.local/share/hyde"

LOG="$HOME/Rice/restore.log"

# ========= Prepare =========
echo ">>> Restore started at $(date)" | tee -a "$LOG"

# ========= Restore Config =========
if [ -d "$SRC_CONFIG" ]; then
  echo ">>> Restoring config files from $SRC_CONFIG -> $DEST_CONFIG" | tee -a "$LOG"
  mkdir -p "$DEST_CONFIG"
  rsync -a "$SRC_CONFIG/" "$DEST_CONFIG/"
else
  echo "!!! Skipped: $SRC_CONFIG not found" | tee -a "$LOG"
fi

# ========= Restore Scripts =========
if [ -d "$SRC_SCRIPT" ]; then
  echo ">>> Restoring scripts from $SRC_SCRIPT -> $DEST_SCRIPT" | tee -a "$LOG"
  mkdir -p "$DEST_SCRIPT"
  rsync -a "$SRC_SCRIPT/" "$DEST_SCRIPT/"
else
  echo "!!! Skipped: $SRC_SCRIPT not found" | tee -a "$LOG"
fi

# ========= Restore .local/share/hypr =========
if [ -d "$SRC_HYPR_SHARE" ]; then
  echo ">>> Restoring local share from $SRC_HYPR_SHARE -> $DEST_HYPR_SHARE" | tee -a "$LOG"
  mkdir -p "$DEST_HYPR_SHARE"
  rsync -a "$SRC_HYPR_SHARE/" "$DEST_HYPR_SHARE/"
else
  echo "!!! Skipped: $SRC_HYPR_SHARE not found" | tee -a "$LOG"
fi

# ========= Restore .local/share/hyde =========
if [ -d "$SRC_HYDE_SHARE" ]; then
  echo ">>> Restoring local share from $SRC_HYDE_SHARE -> $DEST_HYDE_SHARE" | tee -a "$LOG"
  mkdir -p "$DEST_HYDE_SHARE"
  rsync -a "$SRC_HYDE_SHARE/" "$DEST_HYDE_SHARE/"
else
  echo "!!! Skipped: $SRC_HYDE_SHARE not found" | tee -a "$LOG"
fi

echo ">>> Restore finished at $(date)" | tee -a "$LOG"
