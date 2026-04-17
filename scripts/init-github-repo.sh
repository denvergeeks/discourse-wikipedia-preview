#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${1:-discourse-wikipedia-preview}"
GITHUB_USER="${2:-YOUR_GITHUB_USERNAME}"
REMOTE_MODE="${3:-https}"

if [ ! -d "$REPO_NAME" ]; then
  echo "Repository directory '$REPO_NAME' not found"
  exit 1
fi

cd "$REPO_NAME"

git init
git branch -M main
git add .
git commit -m "Initial commit: Discourse Wikipedia Preview theme component"

if [ "$REMOTE_MODE" = "ssh" ]; then
  git remote add origin "git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
else
  git remote add origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
fi

git push -u origin main
