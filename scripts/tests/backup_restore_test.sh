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

original="$TMP/original"
printf '[user]\n\tname = local-only\n' > "$HOME/.gitconfig"
cp "$HOME/.gitconfig" "$original"

bash "$ROOT/scripts/bootstrap.sh" --profile minimal >/dev/null
[ -L "$HOME/.gitconfig" ]

backup_id=$(bash "$ROOT/scripts/backup.sh" list --json | jq -r '.[0].id')
[ -n "$backup_id" ] && [ "$backup_id" != null ]

bash "$ROOT/scripts/bootstrap.sh" --profile minimal >/dev/null
bash "$ROOT/scripts/backup.sh" restore "$backup_id" >/dev/null

[ ! -L "$HOME/.gitconfig" ]
cmp -s "$original" "$HOME/.gitconfig"

printf 'PASS: backup restore contract\n'
