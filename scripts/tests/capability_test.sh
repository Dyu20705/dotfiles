#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$HOME"

bash "$ROOT/scripts/dot" capability enable system >/dev/null
bash "$ROOT/scripts/dot" env --json | jq -e '.capabilities == ["system"]' >/dev/null
bash "$ROOT/scripts/dot" capability doctor system >/dev/null
bash "$ROOT/scripts/dot" capability disable system >/dev/null
bash "$ROOT/scripts/dot" env --json | jq -e '.capabilities == []' >/dev/null

DOTFILES_PROFILE=minimal bash "$ROOT/scripts/dot" env --json \
  | jq -e '.profile == "minimal" and .active_capabilities == []' >/dev/null

printf 'PASS: capability selection contract\n'
