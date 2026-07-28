#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/projects/alpha" "$TMP/projects/group/beta" "$TMP/cache"
git -C "$TMP/projects/alpha" init -q
git -C "$TMP/projects/group/beta" init -q

output=$(DOTFILES_PROJECT_DIRS="$TMP/projects" XDG_CACHE_HOME="$TMP/cache" \
  bash "$ROOT/scripts/dev" --list)

printf '%s\n' "$output" | grep -Fx "$TMP/projects/alpha" >/dev/null
printf '%s\n' "$output" | grep -Fx "$TMP/projects/group/beta" >/dev/null
[ "$(printf '%s\n' "$output" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 2 ]

DOTFILES_PROJECT_DIRS="$TMP/projects" XDG_CACHE_HOME="$TMP/cache" \
  bash "$ROOT/scripts/dev" --refresh >/dev/null
[ -s "$TMP/cache/dotfiles/projects" ]

printf 'PASS: project discovery contract\n'
