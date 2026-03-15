# jinunpark.github.io

Personal blog in Korean and English. Built with Jekyll + jekyll-polyglot.

## Writing a new post

    ./scripts/new-post.sh

## Local development

    bundle install               # first time only
    bash scripts/setup-hooks.sh  # first time only
    bundle exec jekyll serve

Open http://localhost:4000 — you'll be redirected based on your browser language.

## Deployment

Push to `main` → GitHub Actions builds and deploys automatically.
