#!/usr/bin/env bash
set -euo pipefail

# ========= Settings =========
SRC="$HOME/.config"
DEST="$HOME/Rice/backup/config"
LOG="$HOME/Rice/backup/backup.log"

FOLDERS=(
  "Code - OSS/User"
  "Code/User"
  "Kvantum"
  "MangoHud"
  "VSCodium/User"
  "dunst"
  "fastfetch"
  "fish"
  "gtk-3.0"
  "hyde"
  "hypr"
  "kitty"
  "lsd"
  "menus"
  "nwg-look"
  "qt5ct"
  "qt6ct"
  "rofi"
  "satty"
  "starship"
  "swaylock"
  "systemd/user"
  "uwsm"
  "vim"
  "waybar"
  "wlogout"
  "xsettingsd"
  "zsh"
)

FILES=(
  "baloorc"
  "code-flags.conf"
  "codium-flags.conf"
  "dolphinrc"
  "electron-flags.conf"
  "kdeglobals"
  "libinput-gestures.conf"
  "spotify-flags.conf"
  "xdg-terminals.list"
)

# ========= Prepare =========
mkdir -p "$DEST"
echo ">>> Backup started at $(date)" | tee -a "$LOG"

# ========= Copy Folders =========
for folder in "${FOLDERS[@]}"; do
  SRC_PATH="$SRC/$folder"
  DEST_PATH="$DEST/$folder"
  if [ -d "$SRC_PATH" ]; then
    echo ">>> Syncing folder: $SRC_PATH -> $DEST_PATH" | tee -a "$LOG"
    mkdir -p "$(dirname "$DEST_PATH")"
    rsync -a --delete "$SRC_PATH/" "$DEST_PATH/"
  else
    echo "!!! Skipped folder: $SRC_PATH (not found)" | tee -a "$LOG"
  fi
done

# ========= Copy Files =========
for file in "${FILES[@]}"; do
  SRC_PATH="$SRC/$file"
  DEST_PATH="$DEST/$file"
  if [ -f "$SRC_PATH" ]; then
    echo ">>> Copying file: $SRC_PATH -> $DEST_PATH" | tee -a "$LOG"
    mkdir -p "$(dirname "$DEST_PATH")"
    rsync -a "$SRC_PATH" "$DEST_PATH"
  else
    echo "!!! Skipped file: $SRC_PATH (not found)" | tee -a "$LOG"
  fi
done

echo ">>> Backup finished at $(date)" | tee -a "$LOG"
