#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}

git -C "$ROOT" show --check --format= HEAD
git -C "$ROOT" diff --check
git -C "$ROOT" diff --cached --check
