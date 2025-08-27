#!/usr/bin/env bash
set -euo pipefail

# ========= Settings =========
SRC="$HOME/.config"
DEST="$HOME/Rice/backup/config"
LOG="$HOME/Rice/backup.log"
SCRIPT_SRC="$HOME/.local/lib/hyde"
SCRIPT_DEST="$HOME/Rice/backup/script"

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

# ========= Copy HyDE Scripts =========
if [ -d "$SCRIPT_SRC" ]; then
  echo ">>> Syncing scripts (dereferencing symlinks): $SCRIPT_SRC -> $SCRIPT_DEST" | tee -a "$LOG"
  mkdir -p "$SCRIPT_DEST"
  # Use -L if you want to embed the real files for any symlink (common for hyde/user)
  rsync -aL --delete --itemize-changes "$SCRIPT_SRC/" "$SCRIPT_DEST/" | tee -a "$LOG"
else
  echo "!!! Skipped scripts: $SCRIPT_SRC (not found)" | tee -a "$LOG"
fi


# ========= Strip Git Files =========
echo ">>> Removing any git-related files from $DEST and $SCRIPT_DEST" | tee -a "$LOG"

# Remove .git directories recursively
find "$DEST" "$SCRIPT_DEST" -type d -name ".git" -prune -exec rm -rf {} +

# Remove common git metadata files if present
find "$DEST" "$SCRIPT_DEST" -maxdepth 3 -type f \( \
  -name ".gitignore" -o \
  -name ".gitattributes" -o \
  -name ".gitmodules" \
\) -exec rm -f {} +

echo ">>> Git files stripped" | tee -a "$LOG"

# ========= Prune Code folder =========
CODE_DEST="$DEST/Code/User"
if [ -d "$CODE_DEST" ]; then
  echo ">>> Pruning Code backup, keeping only settings.json and keybindings.json" | tee -a "$LOG"
  find "$CODE_DEST" -type f ! -name "settings.json" ! -name "keybindings.json" -delete
  find "$CODE_DEST" -type d -empty -delete
fi

echo ">>> Backup finished at $(date)" | tee -a "$LOG"
