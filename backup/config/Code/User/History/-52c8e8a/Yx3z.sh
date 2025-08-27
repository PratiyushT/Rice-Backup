
#!/usr/bin/env bash
set -euo pipefail

# Target location
TARGET="$HOME/.config/zsh"

# Backup location with timestamp
BACKUP="$HOME/.config/zsh.backup.$(date +%Y%m%d-%H%M%S)"

echo ">>> Replacing zsh config..."

# 1. Backup if target exists
if [ -d "$TARGET" ]; then
  echo ">>> Backing up existing $TARGET -> $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

# 2. Copy ./zsh into place
if [ -d "./zsh" ]; then
  echo ">>> Copying ./zsh -> $TARGET"
  cp -r ./zsh "$TARGET"
else
  echo "Error: ./zsh folder not found in current directory"
  exit 1
fi

echo ">>> Done. New config at $TARGET"


