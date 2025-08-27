#!/usr/bin/env bash
set -euo pipefail

# ========= Settings =========
SRC="$HOME/.config"
DEST="$HOME/Rice/backup"
LISTFILE="$DEST/backup-list.txt"
Script="${Script:-$HOME/.local/lib/hyde}"   # your scripts root
MAX_SIZE=95m                                 # per-file size cap

mkdir -p $DEST
# Set to "true" if you want to scrub old junk from DEST before syncing
CLEAN_PREVIOUS="${CLEAN_PREVIOUS:-true}"

# ========= Exclude patterns (git-safe) =========
# Central list so both rsyncs reuse it
read -r -d '' EXCLUDES <<'EOF'
# Git
--exclude='.git/'
--exclude='.gitignore'

# Your accidental backup tree
--exclude='.config.bkp/'

# Common caches and temp
--exclude='*cache*/'
--exclude='Cache/'
--exclude='Caches/'
--exclude='GPUCache/'
--exclude='__pycache__/'
--exclude='node_modules/'
--exclude='*.tmp'
--exclude='*.lock'
--exclude='*.log'
--exclude='*.bkp'

# VS Code / Code - OSS heavy runtime data
--exclude='Code - OSS/Code Cache/'
--exclude='Code - OSS/CachedData/'
--exclude='Code - OSS/CachedProfilesData/'
--exclude='Code - OSS/GPUCache/'
--exclude='Code - OSS/Crashpad/'
--exclude='Code - OSS/logs/'
--exclude='Code - OSS/Local Storage/'
--exclude='Code - OSS/Service Worker/'
--exclude='Code - OSS/WebStorage/'
--exclude='Code - OSS/blob_storage/'
--exclude='Code - OSS/SharedStorage/'
--exclude='Code - OSS/DawnWebGPUCache/'
--exclude='Code - OSS/DawnGraphiteCache/'
--exclude='Code - OSS/User/workspaceStorage/'
# Optional: keep settings and snippets, but drop volatile sqlite/vscdb backups
--exclude='Code - OSS/User/globalStorage/state.vscdb*'

# Chromium/Electron-style caches that many apps reuse
--exclude='*/Service Worker/'
--exclude='*/Code Cache/'
--exclude='*/WebStorage/'
--exclude='*/Crashpad/'
--exclude='*/GPUCache/'
--exclude='*/Local Storage/'

# LevelDB and misc runtime DBs that bloat repos
--exclude='*/leveldb/'
--exclude='*/IndexedDB/'
--exclude='*/databases/'

# OS and editor detritus
--exclude='.DS_Store'
--exclude='Thumbs.db'
EOF

# ========= Helpers =========
rsync_copy () {
  # $1 = source dir, $2 = dest dir
  local src="$1" dst="$2"

  rsync -a \
    --human-readable \
    --max-size="${MAX_SIZE}" \
    --prune-empty-dirs \
    ${EXCLUDES} \
    "${src%/}/" "${dst%/}/"
}

scrub_dest () {
  # Remove junk that may have been copied by older scripts
  # Mirrors the exclude set but as explicit deletes in DEST
  local root="$1"
  # Delete known junk directories if present
  find "$root" -type d \( \
      -name .git -o -name '*cache*' -o -name Cache -o -name Caches -o \
      -name GPUCache -o -name '__pycache__' -o -name 'node_modules' -o \
      -path '*/Code - OSS/Code Cache' -o \
      -path '*/Code - OSS/CachedData' -o \
      -path '*/Code - OSS/CachedProfilesData' -o \
      -path '*/Code - OSS/GPUCache' -o \
      -path '*/Code - OSS/Crashpad' -o \
      -path '*/Code - OSS/logs' -o \
      -path '*/Code - OSS/Local Storage' -o \
      -path '*/Code - OSS/Service Worker' -o \
      -path '*/Code - OSS/WebStorage' -o \
      -path '*/Code - OSS/blob_storage' -o \
      -path '*/Code - OSS/SharedStorage' -o \
      -path '*/Code - OSS/DawnWebGPUCache' -o \
      -path '*/Code - OSS/DawnGraphiteCache' -o \
      -path '*/Code - OSS/User/workspaceStorage' -o \
      -name 'Service Worker' -o -name 'Code Cache' -o -name WebStorage -o \
      -name Crashpad -o -name GPUCache -o -name 'Local Storage' -o \
      -name leveldb -o -name IndexedDB -o -name databases -o \
      -name '.config.bkp' \
    \) -prune -exec rm -rf {} + 2>/dev/null || true

  # Delete unwanted files by pattern
  find "$root" -type f \( \
      -name '*.tmp' -o -name '*.lock' -o -name '*.log' -o -name '*.bkp' -o \
      -name '.DS_Store' -o -name 'Thumbs.db' -o -name '.gitignore' \
    \) -delete 2>/dev/null || true

  # Very large files that might have slipped in earlier
  find "$root" -type f -size +95M -delete 2>/dev/null || true
}

# ========= Run =========
echo ">>> Preparing ${DEST}"
mkdir -p "${DEST}"

if [[ "${CLEAN_PREVIOUS}" == "true" ]]; then
  echo ">>> Scrubbing old junk in ${DEST}"
  scrub_dest "${DEST}"
fi

echo ">>> Syncing ${SRC} -> ${DEST}"
rsync_copy "${SRC}" "${DEST}"

if [[ -d "${Script}/user" ]]; then
  echo ">>> Syncing ${Script}/user -> ${DEST}/user"
  mkdir -p "${DEST}/user"
  rsync_copy "${Script}/user" "${DEST}/user"
fi

# Build a plain list of what is in DEST now
echo ">>> Writing ${LISTFILE}"
(
  cd "${DEST}"
  find . -type d -o -type f | sort
) > "${LISTFILE}"

echo ">>> Backup complete. List saved to ${LISTFILE}"
