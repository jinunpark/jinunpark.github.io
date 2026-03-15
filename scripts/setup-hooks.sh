#!/usr/bin/env bash
# scripts/setup-hooks.sh
# Run once after cloning: bash scripts/setup-hooks.sh

set -e

echo "→ Configuring git hooks path..."
git config core.hooksPath hooks
echo "✓ core.hooksPath set to hooks/"

echo "→ Checking for aspell (English spell checker)..."
if command -v aspell >/dev/null 2>&1; then
  echo "✓ aspell found: $(aspell --version | head -1)"
else
  echo "⚠ aspell not found. English spell check will be skipped."
  echo "  Install: brew install aspell  (macOS)"
  echo "           sudo apt install aspell  (Ubuntu/Debian)"
fi

echo ""
echo "✓ Setup complete. Pre-commit hook is now active."
