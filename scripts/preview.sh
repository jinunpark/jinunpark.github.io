#!/usr/bin/env bash
# scripts/preview.sh
# Start a local Jekyll preview server.
# Usage: ./scripts/preview.sh [--drafts] [--port PORT]

set -e

DRAFTS=""
PORT="4000"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --drafts)
    DRAFTS="--drafts"
    shift
    ;;
  --port)
    PORT="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

if command -v bundle &>/dev/null; then
  BUNDLE="bundle"
elif [ -x "$HOME/.rbenv/shims/bundle" ]; then
  BUNDLE="$HOME/.rbenv/shims/bundle"
else
  echo "Error: bundle not found. Install rbenv and run 'bundle install'."
  exit 1
fi

echo "Starting preview at http://localhost:${PORT}"
if [ -n "$DRAFTS" ]; then
  echo "Including drafts."
fi

exec "$BUNDLE" exec jekyll serve --port "$PORT" $DRAFTS
