#!/usr/bin/env bash
# scripts/new-post.sh
# Scaffold a new blog post with correct filename and front matter.
# Usage: ./scripts/new-post.sh [--title "..."] [--lang ko|en|both] [--tags "tag1,tag2"] [--slug my-post]

set -e

TITLE=""
LANG=""
TAGS=""
SLUG=""

# ── Parse flags ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --lang)  LANG="$2";  shift 2 ;;
    --tags)  TAGS="$2";  shift 2 ;;
    --slug)  SLUG="$2";  shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Prompts for missing fields ──
if [ -z "$TITLE" ]; then
  read -rp "Title: " TITLE
fi
if [ -z "$LANG" ]; then
  read -rp "Language [ko/en/both]: " LANG
fi
if [ -z "$TAGS" ]; then
  read -rp "Tags (comma-separated): " TAGS
fi

# ── Derive slug from title if not provided ──
if [ -z "$SLUG" ]; then
  # Strip all non-ASCII and non-alphanumeric characters (safe across all locales)
  SLUG=$(echo "$TITLE" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 ]//g' \
    | sed 's/ \+/-/g' \
    | sed 's/^-\+//;s/-\+$//' \
    | cut -c1-50)
  # If title was all non-ASCII (e.g., Korean), prompt for a manual slug
  if [ -z "$SLUG" ]; then
    read -rp "Could not derive slug from title. Enter slug manually (e.g. my-post): " SLUG
  fi
  echo "Slug: $SLUG"
fi

DATE=$(date +%Y-%m-%d)

# ── Validate lang ──
if [ "$LANG" != "ko" ] && [ "$LANG" != "en" ] && [ "$LANG" != "both" ]; then
  echo "Error: --lang must be ko, en, or both"
  exit 1
fi

# ── Build YAML tags array ──
format_tags() {
  local raw="$1"
  local result="["
  IFS=',' read -ra PARTS <<< "$raw"
  for i in "${!PARTS[@]}"; do
    TAG=$(echo "${PARTS[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ $i -gt 0 ]; then result+=", "; fi
    result+="$TAG"
  done
  result+="]"
  echo "$result"
}

TAGS_YAML=$(format_tags "$TAGS")

# ── Create file function ──
create_post() {
  local lang="$1"
  local layout="post-${lang}"
  local filename="_posts/${DATE}-${SLUG}-${lang}.md"

  if [ -e "$filename" ]; then
    echo "Error: $filename already exists. Aborting."
    exit 1
  fi

  cat > "$filename" << EOF
---
layout: ${layout}
lang: ${lang}
title: "${TITLE}"
date: ${DATE}
tags: ${TAGS_YAML}
slug: ${SLUG}
---

EOF

  echo "✓ Created: $filename"

}

# ── Create file(s) and open in editor ──
CREATED_FILES=()

if [ "$LANG" = "both" ]; then
  create_post "ko"
  create_post "en"
  CREATED_FILES+=("_posts/${DATE}-${SLUG}-ko.md" "_posts/${DATE}-${SLUG}-en.md")
else
  create_post "$LANG"
  CREATED_FILES+=("_posts/${DATE}-${SLUG}-${LANG}.md")
fi

if [ -n "$EDITOR" ]; then
  $EDITOR "${CREATED_FILES[@]}"
fi
