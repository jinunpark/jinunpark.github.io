# Bilingual Blog Design Spec
**Date:** 2026-03-15
**Repo:** jinunpark.github.io
**Stack:** Jekyll + jekyll-polyglot, GitHub Actions, GitHub Pages

---

## Overview

A personal blog serving mixed content (technical + personal) in Korean and English from a single Jekyll repository. Posts can be bilingual or mono-lingual. Each language has a visually distinct theme. The site auto-detects the user's browser language on first visit and routes them to the appropriate language namespace. A persistent language switcher is present on every page.

---

## Architecture

### Tech Stack
- **Jekyll** with **jekyll-polyglot** plugin for i18n routing
- **GitHub Actions** for build + deploy (required because jekyll-polyglot is not supported by native GitHub Pages Jekyll)
- Deployed to `gh-pages` branch → served at `jinunpark.github.io`

### Directory Structure

```
jinunpark.github.io/
├── _config.yml
├── _layouts/
│   ├── default-ko.html
│   ├── default-en.html
│   ├── post-ko.html
│   ├── post-en.html
│   ├── page-ko.html
│   └── page-en.html
├── _includes/
│   ├── lang-switcher.html
│   ├── header-ko.html
│   └── header-en.html
├── _posts/
│   ├── YYYY-MM-DD-slug.ko.md
│   └── YYYY-MM-DD-slug.en.md   # optional translation
├── about.ko.md                  # → /ko/about/
├── about.en.md                  # → /en/about/
├── assets/
│   ├── css/
│   │   ├── theme-ko.css
│   │   └── theme-en.css
│   └── js/
│       └── lang-detect.js
├── index.html                   # root redirect via lang-detect.js
├── scripts/
│   └── check-post.sh            # pre-commit checker script
├── .git/hooks/
│   └── pre-commit               # calls check-post.sh
├── .github/
│   └── workflows/
│       └── deploy.yml
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-03-15-bilingual-blog-design.md
```

### Jekyll Config (`_config.yml`)

Key polyglot settings:
```yaml
languages: ["ko", "en"]
default_lang: "ko"
exclude_from_localization: ["assets", "scripts"]
parallel_localization: false
```

---

## Language Detection & Routing

### URL Namespacing
- All Korean content under `/ko/` — e.g., `/ko/about/`, `/ko/2026/03/15/slug/`
- All English content under `/en/` — e.g., `/en/about/`, `/en/2026/03/15/slug/`
- Site root (`/`) contains only `index.html` which immediately redirects

### First Visit Detection (`lang-detect.js`)
1. Check `localStorage` for `preferred_lang` key
2. If found, redirect to `/<preferred_lang>/`
3. If not found, read `navigator.language`
4. If starts with `ko` → redirect to `/ko/`, else → redirect to `/en/`
5. Store result in `localStorage`

### Language Switcher
- Present in every page header (top-right)
- If translation exists for current post → links directly to translated post
- If no translation exists → links to the other language's homepage with tooltip: *"번역이 없습니다" / "No translation available"*
- Clicking switcher updates `localStorage`

---

## Themes

### Korean Theme (`theme-ko.css`)
| Property | Value |
|---|---|
| Background | `#faf8f5` (warm off-white) |
| Text | `#1a1a1a` |
| Accent | `#8b5e3c` (earthy brown) |
| Body font | Noto Serif KR |
| UI font | Noto Sans KR |
| Post list style | Card-style list, generous line-height |
| Post max-width | ~780px |
| Feel | Warm, editorial |

### English Theme (`theme-en.css`)
| Property | Value |
|---|---|
| Background | `#ffffff` |
| Text | `#111111` |
| Accent | `#2563eb` (blue) |
| Body font | Inter |
| Code font | DM Mono |
| Post list style | Single-column minimal list |
| Post max-width | ~680px |
| Feel | Clean, minimal, developer-focused |

### Shared
- Mobile-first responsive layout
- Syntax highlighting for code blocks (Rouge)
- Language switcher in header on every page

---

## Content Model

### Posts
- Filename: `YYYY-MM-DD-slug.ko.md` / `YYYY-MM-DD-slug.en.md`
- polyglot links files sharing the same slug as translation pairs
- A post with only one language file appears only in that language's namespace
- Front matter:
  ```yaml
  ---
  layout: post-ko       # or post-en
  lang: ko              # or en
  title: "제목"
  date: 2026-03-15
  tags: [개발, 도구]
  ---
  ```

### Pages (About, etc.)
- Files: `about.ko.md`, `about.en.md` in repo root
- URLs: `/ko/about/`, `/en/about/`
- Front matter:
  ```yaml
  ---
  layout: page-ko
  lang: ko
  title: 소개
  permalink: /ko/about/
  ---
  ```
- If only one language version exists, switcher falls back to other language's homepage

---

## Pre-commit Post Checker

Script: `scripts/check-post.sh`, invoked by `.git/hooks/pre-commit` on every commit touching `_posts/` or `about.*.md`.

| Check | KO | EN |
|---|---|---|
| Required front matter present (`title`, `date`, `lang`, `tags`) | ✓ | ✓ |
| Filename matches `YYYY-MM-DD-slug.lang.md` format | ✓ | ✓ |
| No broken local image references | ✓ | ✓ |
| Spell check via `aspell` | — | ✓ |

On failure: checker prints a descriptive error and blocks the commit.

---

## Deployment (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`, triggers on push to `main`.

Steps:
1. Checkout repo
2. Set up Ruby + bundle install (includes jekyll-polyglot)
3. Run `bundle exec jekyll build`
4. Deploy `_site/` to `gh-pages` branch using `peaceiris/actions-gh-pages`

Result: site live at `https://jinunpark.github.io`

---

## Out of Scope

- Comments system
- Newsletter / subscription
- Premium / gated content
- Search functionality
- Analytics (can be added later)
