#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}

DOTFILES_ROOT="$ROOT" bash "$ROOT/scripts/check-whitespace.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scripts"
cp "$ROOT/scripts/check-whitespace.sh" "$tmp/scripts/check-whitespace.sh"

git -C "$tmp" init -q
git -C "$tmp" config user.email test@example.invalid
git -C "$tmp" config user.name test
printf 'clean\n' > "$tmp/file.txt"
git -C "$tmp" add .
git -C "$tmp" commit -qm clean

DOTFILES_ROOT="$tmp" bash "$tmp/scripts/check-whitespace.sh"

printf 'committed trailing space   \n' > "$tmp/file.txt"
git -C "$tmp" add file.txt
git -C "$tmp" commit -qm bad-whitespace

if DOTFILES_ROOT="$tmp" bash "$tmp/scripts/check-whitespace.sh" >/dev/null 2>&1; then
  printf 'whitespace check ignored committed trailing whitespace\n' >&2
  exit 1
fi

printf 'PASS: committed whitespace detection\n'
