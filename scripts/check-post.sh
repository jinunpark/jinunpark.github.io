#!/usr/bin/env bash
# scripts/check-post.sh
# Usage: check-post.sh <file1> [file2 ...]
# Validates post files before commit.
#
# Note: intentionally NO `set -e` — we use an ERRORS counter to collect all
# failures before exiting so the user sees every problem at once.

ERRORS=0

red()   { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }
warn()  { echo -e "\033[33m$*\033[0m"; }

check_frontmatter_field() {
  local file="$1"
  local field="$2"
  if ! grep -qE "^${field}:" "$file"; then
    red "  ✗ Missing required front matter field: '${field}' in $file"
    ERRORS=$((ERRORS + 1))
  fi
}

get_frontmatter_value() {
  local file="$1"
  local field="$2"
  grep -E "^${field}:" "$file" | head -1 | sed "s/^${field}:[[:space:]]*//" | tr -d '"'"'"'[:space:]'
}

for FILE in "$@"; do
  echo "Checking: $FILE"

  # ── Required fields for all posts ──
  for FIELD in title date tags slug; do
    check_frontmatter_field "$FILE" "$FIELD"
  done

  LANG=$(get_frontmatter_value "$FILE" "lang")
  LAYOUT=$(get_frontmatter_value "$FILE" "layout")

  # ── lang-specific checks ──
  if [ -n "$LANG" ]; then
    # Check lang field is valid
    if [ "$LANG" != "ko" ] && [ "$LANG" != "en" ]; then
      red "  ✗ Invalid lang value '$LANG' — must be 'ko' or 'en' in $FILE"
      ERRORS=$((ERRORS + 1))
    fi

    # Check layout matches lang
    if [ -n "$LAYOUT" ]; then
      EXPECTED_SUFFIX="$LANG"
      if ! echo "$LAYOUT" | grep -qE "\-${EXPECTED_SUFFIX}$"; then
        red "  ✗ Layout '$LAYOUT' does not match lang '$LANG' — expected layout ending in '-${EXPECTED_SUFFIX}' in $FILE"
        ERRORS=$((ERRORS + 1))
      fi
    fi

    # Check filename suffix (only for _posts files, not about pages)
    if echo "$FILE" | grep -q "^_posts/"; then
      BASENAME=$(basename "$FILE")
      if ! echo "$BASENAME" | grep -qE "\-${LANG}\.md$"; then
        red "  ✗ Filename '$BASENAME' must end in '-${LANG}.md' for lang: ${LANG}"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  fi

  # ── Broken local image references ──
  LOCAL_IMAGES=$(grep -oE '!\[.*?\]\(/[^)]+\)' "$FILE" | grep -oE '/[^)]+' || true)
  for IMG_PATH in $LOCAL_IMAGES; do
    if [ ! -f ".${IMG_PATH}" ]; then
      red "  ✗ Broken local image reference: $IMG_PATH in $FILE"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # ── English spell check (aspell) ──
  if [ "$LANG" = "en" ]; then
    if command -v aspell >/dev/null 2>&1; then
      # Strip YAML front matter and Markdown syntax before spell checking
      CONTENT=$(awk '/^---/{p++; next} p==2{print}' "$FILE")
      MISSPELLED=$(echo "$CONTENT" | \
        sed 's/```[^`]*```//g' | \
        sed 's/`[^`]*`//g' | \
        sed 's/\[.*\]([^)]*)//' | \
        aspell --lang=en_US list 2>/dev/null | sort -u || true)
      if [ -n "$MISSPELLED" ]; then
        warn "  ⚠ Possible misspellings in $FILE (review manually):"
        echo "$MISSPELLED" | sed 's/^/    - /'
      fi
    else
      warn "  ⚠ aspell not installed — skipping spell check for $FILE"
    fi
  fi

  echo ""
done

if [ "$ERRORS" -gt 0 ]; then
  red "Pre-commit check failed with $ERRORS error(s). Fix them and try again."
  exit 1
fi

green "✓ All post checks passed."
exit 0
