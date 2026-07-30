#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}

if git -C "$ROOT" rev-parse --verify HEAD^1 >/dev/null 2>&1; then
  git -C "$ROOT" diff --check HEAD^1 HEAD
else
  git -C "$ROOT" show --check --format= HEAD
fi

git -C "$ROOT" diff --check
git -C "$ROOT" diff --cached --check
