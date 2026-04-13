#!/usr/bin/env bash
# scripts/watch-drafts.sh
# Watches _drafts/ for changes to source draft files (YYYYMMDD_*.md) and
# re-runs preview-drafts.sh automatically.
#
# Usage:
#   ./scripts/watch-drafts.sh
#
# Requires inotify-tools:
#   sudo apt install inotify-tools

set -e

DRAFTS_DIR="_drafts"
SCRIPT="$(dirname "$0")/preview-drafts.sh"

if ! command -v inotifywait &>/dev/null; then
  echo "Error: inotifywait not found. Install it with: sudo apt install inotify-tools"
  exit 1
fi

echo "Watching $DRAFTS_DIR for changes... (Ctrl+C to stop)"

# Run once on startup
"$SCRIPT"

inotifywait -m -e close_write,create,delete,moved_to,moved_from \
  --include '/[0-9]{8}_.*\.md$' \
  "$DRAFTS_DIR" |
while read -r _dir _event _file; do
  echo ""
  echo "[watch] $DRAFTS_DIR/$_file changed ($_event), regenerating..."
  "$SCRIPT"
done
