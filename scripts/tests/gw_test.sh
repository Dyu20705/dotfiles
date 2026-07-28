#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
worktrees="$TMP/worktrees"
mkdir -p "$repo"
git -C "$repo" init -q -b main
git -C "$repo" config user.name test
git -C "$repo" config user.email test@example.invalid
printf 'base\n' > "$repo/file.txt"
git -C "$repo" add file.txt
git -C "$repo" commit -qm initial

(
  cd "$repo"
  DOTFILES_WORKTREE_ROOT="$worktrees" bash "$ROOT/scripts/gw" new feature main >/dev/null
)
feature_path=$(find "$worktrees" -mindepth 1 -maxdepth 2 -type d -name feature -print -quit)
[ -n "$feature_path" ]
printf 'dirty\n' >> "$feature_path/file.txt"

if (cd "$repo" && DOTFILES_WORKTREE_ROOT="$worktrees" bash "$ROOT/scripts/gw" remove feature >/dev/null 2>&1); then
  printf 'dirty worktree removal unexpectedly succeeded\n' >&2
  exit 1
fi

(
  cd "$repo"
  DOTFILES_WORKTREE_ROOT="$worktrees" bash "$ROOT/scripts/gw" remove feature --force >/dev/null
)
[ ! -e "$feature_path" ]

printf 'PASS: safe worktree contract\n'
