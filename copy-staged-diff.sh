#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a Git repository." >&2
  exit 1
fi

diff_content="$(git diff --cached --no-ext-diff)"

if [ -z "$diff_content" ]; then
  echo "No staged changes found."
  exit 0
fi

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$diff_content" | pbcopy
elif command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$diff_content" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
  printf '%s' "$diff_content" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
  printf '%s' "$diff_content" | xsel --clipboard --input
elif command -v clip.exe >/dev/null 2>&1; then
  printf '%s' "$diff_content" | clip.exe
elif command -v clip >/dev/null 2>&1; then
  printf '%s' "$diff_content" | clip
else
  echo "Error: no clipboard command found." >&2
  echo "Install one of: pbcopy, wl-copy, xclip, xsel, clip.exe" >&2
  exit 1
fi

echo "Copied staged Git diff to clipboard."
