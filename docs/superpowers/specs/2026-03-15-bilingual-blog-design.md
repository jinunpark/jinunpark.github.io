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
- **Jekyll** (Ruby 3.2) with **jekyll-polyglot** plugin for i18n routing
- **GitHub Actions** for build + deploy (required because jekyll-polyglot is not supported by native GitHub Pages Jekyll)
- Deployed to `gh-pages` branch → served at `jinunpark.github.io`
- `Gemfile` and `Gemfile.lock` committed to repo for reproducible builds

### Directory Structure

```
jinunpark.github.io/
├── _config.yml
├── Gemfile
├── Gemfile.lock
├── _layouts/
│   ├── default-ko.html       # loads theme-ko.css; includes hreflang tags
│   ├── default-en.html       # loads theme-en.css; includes hreflang tags
│   ├── post-ko.html          # extends default-ko.html
│   ├── post-en.html          # extends default-en.html
│   ├── page-ko.html          # extends default-ko.html
│   └── page-en.html          # extends default-en.html
├── _includes/
│   ├── lang-switcher.html
│   ├── header-ko.html
│   └── header-en.html
├── _posts/
│   ├── 2026-03-15-dev-tools-ko.md   # lang: ko, slug: dev-tools
│   └── 2026-03-15-dev-tools-en.md   # lang: en, slug: dev-tools (optional)
├── about.ko.md                       # → /ko/about/, slug: about
├── about.en.md                       # → /en/about/, slug: about (optional)
├── assets/
│   ├── css/
│   │   ├── theme-ko.css
│   │   └── theme-en.css
│   └── js/
│       └── lang-detect.js
├── index.html                        # root: noscript fallback + JS redirect
├── hooks/                            # committed hook scripts
│   └── pre-commit                    # calls scripts/check-post.sh
├── scripts/
│   ├── check-post.sh                 # pre-commit checker
│   └── setup-hooks.sh               # run once after clone: sets core.hooksPath
├── .github/
│   └── workflows/
│       └── deploy.yml
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-03-15-bilingual-blog-design.md
```

### Jekyll Config (`_config.yml`)

```yaml
url: "https://jinunpark.github.io"
baseurl: ""
permalink: /:lang/:year/:month/:day/:slug/

languages: ["ko", "en"]
default_lang: "ko"
exclude_from_localization: ["assets", "scripts", "hooks"]
parallel_localization: false

plugins:
  - jekyll-polyglot
```

The `permalink` format uses `:slug` (the front matter `slug:` field, not the filename), which produces clean URLs without the `-ko` / `-en` filename suffix. For example, `2026-03-15-dev-tools-ko.md` with `slug: dev-tools` and `lang: ko` resolves to `/ko/2026/03/15/dev-tools/`.

---

## Content Model

### How jekyll-polyglot Works
jekyll-polyglot builds the site once per language. A post with `lang: ko` in front matter is included only in the Korean build (served under `/ko/`). A post with `lang: en` appears only under `/en/`.

**Mono-lingual posts** (no `lang:` field): appear in all language builds at the same URL. These should use a language-neutral layout (e.g., `layout: post-ko` if the content is Korean) — the author is responsible for setting an appropriate layout. The pre-commit checker skips the filename suffix and layout/lang consistency checks for `lang:`-less posts, but does validate all other front matter fields.

### Post Filenames
Convention: `YYYY-MM-DD-title-lang.md`

Examples:
```
_posts/2026-03-15-dev-tools-ko.md    # Korean post
_posts/2026-03-15-dev-tools-en.md    # English translation (optional)
```

Two files cannot share the same filename — the `-ko`/`-en` suffix distinguishes them on the filesystem. The `slug:` front matter field controls the final URL (without the suffix) and is the translation key used by the switcher.

### Post Front Matter
```yaml
---
layout: post-ko          # must match lang: value (post-ko ↔ lang:ko, post-en ↔ lang:en)
lang: ko
title: "내가 매일 쓰는 개발 도구 모음"
date: 2026-03-15
tags: [개발, 도구]        # localized tags per language
slug: dev-tools           # controls URL; shared with translation counterpart
---
```

### Layout/Lang Consistency Rule
When `lang:` is present, the `layout:` field must match:
- `lang: ko` → `layout: post-ko` or `layout: page-ko`
- `lang: en` → `layout: post-en` or `layout: page-en`

Posts without `lang:` are exempt from this rule. The pre-commit checker enforces this — a mismatch blocks the commit.

### Pages (About, etc.)
```yaml
---
layout: page-ko
lang: ko
title: 소개
slug: about              # required — used by switcher to find counterpart in site.pages
permalink: /ko/about/
---
```

If only one language version of a page exists, the switcher falls back to the other language's homepage.

### Tags
Tags are localized per language. Korean posts use Korean tags; English posts use English tags. No cross-language tag pages.

**Tag page generation:** Tag index pages are generated by a custom Jekyll generator plugin (`_plugins/tag_generator.rb`). For each unique tag in a given language's build, it creates a page at `/ko/tags/<tag>/` or `/en/tags/<tag>/` listing all posts with that tag.

---

## Language Detection & Routing

### URL Namespacing
- Korean: `/ko/` prefix — e.g., `/ko/about/`, `/ko/2026/03/15/dev-tools/`
- English: `/en/` prefix — e.g., `/en/about/`, `/en/2026/03/15/dev-tools/`
- Root `/` contains only `index.html` for initial redirect

### Root `index.html`
The root page runs `lang-detect.js` on load. For users without JavaScript, a `<noscript>` block renders links to both language homepages:

```html
<noscript>
  <p>Choose your language: <a href="/ko/">한국어</a> | <a href="/en/">English</a></p>
</noscript>
```

`index.html` also includes `hreflang` link tags:
```html
<link rel="alternate" hreflang="ko" href="https://jinunpark.github.io/ko/" />
<link rel="alternate" hreflang="en" href="https://jinunpark.github.io/en/" />
```

### `lang-detect.js` Logic
This script runs **only when included on the root `/` page**. Language-namespaced pages do not include this script.

```
1. Read localStorage["blog_preferred_lang"]
2. If found → redirect to /<value>/
3. If not found → read navigator.language
4. If starts with "ko" → redirect to /ko/, else → redirect to /en/
5. Store result in localStorage["blog_preferred_lang"]
```

The key `blog_preferred_lang` is namespaced to avoid collisions with other sites' localStorage entries.

Without JavaScript, the user sees the `<noscript>` links and manually chooses — preference is not stored, but navigation still works fully.

### Language Switcher (`lang-switcher.html`)
Present in every page header (top-right corner).

**Liquid logic to detect translation (searches both `site.posts` and `site.pages`):**
```liquid
{% assign current_slug = page.slug %}
{% assign current_lang = page.lang %}
{% assign target_lang = "en" %}
{% if current_lang == "en" %}{% assign target_lang = "ko" %}{% endif %}

{% assign translation = nil %}

{% comment %} Search posts {% endcomment %}
{% for p in site.posts %}
  {% if p.slug == current_slug and p.lang == target_lang %}
    {% assign translation = p %}
    {% break %}
  {% endif %}
{% endfor %}

{% comment %} If not found in posts, search pages {% endcomment %}
{% if translation == nil %}
  {% for p in site.pages %}
    {% if p.slug == current_slug and p.lang == target_lang %}
      {% assign translation = p %}
      {% break %}
    {% endif %}
  {% endfor %}
{% endif %}
```

- If `translation` found → render `<a href="{{ translation.url }}">` and update `localStorage["blog_preferred_lang"]` on click via an `onclick` handler
- If `translation` nil → render a `<span>` styled as greyed-out with `title="번역이 없습니다"` / `title="No translation available"` and `style="pointer-events: none; opacity: 0.4"` (not clickable)
- Without JS: the `<a>` link still navigates; only the `localStorage` update is skipped — preference is not persisted but switching works

### `hreflang` Tags in Layouts
Every layout (`default-ko.html`, `default-en.html`) includes `hreflang` link tags in `<head>`. The same Liquid translation-lookup logic from the switcher is reused:

- If translation found: emit reciprocal `hreflang` tags for both languages
- If no translation: emit only the self-referencing `hreflang` tag (`hreflang="{{ page.lang }}"`)

---

## Themes

### CSS Loading
Each layout hardcodes its own stylesheet:
- `default-ko.html` → `<link rel="stylesheet" href="/assets/css/theme-ko.css">`
- `default-en.html` → `<link rel="stylesheet" href="/assets/css/theme-en.css">`

`assets/` is excluded from localization so CSS is served at a single path without language prefix.

### Font Loading
Fonts are loaded via Google Fonts `@import` at the top of each theme CSS file:

```css
/* theme-ko.css */
@import url('https://fonts.googleapis.com/css2?family=Noto+Serif+KR:wght@400;600;700&family=Noto+Sans+KR:wght@400;500&display=swap');
```

```css
/* theme-en.css */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=DM+Mono:ital,wght@0,400;0,500;1,400&display=swap');
```

System font stacks are declared as fallbacks in `font-family` declarations in case Google Fonts is unavailable.

### Korean Theme (`theme-ko.css`)
| Property | Value |
|---|---|
| Background | `#faf8f5` (warm off-white) |
| Text | `#1a1a1a` |
| Accent | `#8b5e3c` (earthy brown) |
| Body font | Noto Serif KR, serif |
| UI font | Noto Sans KR, sans-serif |
| Post list style | Card-style list, generous line-height |
| Post max-width | ~780px |
| Feel | Warm, editorial |

### English Theme (`theme-en.css`)
| Property | Value |
|---|---|
| Background | `#ffffff` |
| Text | `#111111` |
| Accent | `#2563eb` (blue) |
| Body font | Inter, sans-serif |
| Code font | DM Mono, monospace |
| Post list style | Single-column minimal list |
| Post max-width | ~680px |
| Feel | Clean, minimal, developer-focused |

### Shared
- Mobile-first responsive layout
- Syntax highlighting via Rouge
- Language switcher in header on every page

---

## Pre-commit Post Checker

### Distribution
The `hooks/` directory is committed in the repo root. After cloning, run once:
```bash
bash scripts/setup-hooks.sh
```
This runs `git config core.hooksPath hooks`, pointing git to the committed hooks directory. The script also checks for `aspell` and prints an install reminder if missing (`brew install aspell` / `sudo apt install aspell`).

### Script: `scripts/check-post.sh`
Runs on staged files in `_posts/` or matching `about.*.md`.

| Check | KO | EN | `lang:`-less |
|---|---|---|---|
| Required front matter (`title`, `date`, `lang`, `tags`, `slug`) | ✓ | ✓ | ✓ (except `lang`) |
| `layout:` matches `lang:` | ✓ | ✓ | skipped |
| Filename ends in `-ko.md` for `lang:ko`, `-en.md` for `lang:en` | ✓ | ✓ | skipped |
| No broken local image references | ✓ | ✓ | ✓ |
| Spell check via `aspell` (skipped with warning if `aspell` not installed) | — | ✓ | — |

On any failure: prints a descriptive error and exits with code 1, blocking the commit.

---

## Deployment (GitHub Actions)

File: `.github/workflows/deploy.yml`, triggers on push to `main`.

```yaml
env:
  JEKYLL_ENV: production

steps:
  - uses: actions/checkout@v4
  - uses: ruby/setup-ruby@v1
    with:
      ruby-version: '3.2'
      bundler-cache: true        # uses Gemfile.lock for reproducible builds
  - run: bundle exec jekyll build
  - uses: peaceiris/actions-gh-pages@v3
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}   # built-in token, no extra setup
      publish_dir: ./_site
      publish_branch: gh-pages
```

`JEKYLL_ENV: production` ensures production-mode behavior for polyglot and any analytics snippets. The `gh-pages` branch is created automatically by `peaceiris/actions-gh-pages` on first deploy. GitHub Pages must be configured in repo Settings → Pages → Source: `gh-pages` branch.

Note: `peaceiris/actions-gh-pages@v3` is pinned to a major version tag. For this personal blog this is acceptable. If stricter supply-chain security is needed in future, pin to a commit SHA.

---

## Out of Scope

- Comments system
- Newsletter / subscription
- Premium / gated content
- Search functionality
- Analytics (can be added later as a script tag in layouts)
