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

# Restore identifiers are untrusted CLI input and must not traverse outside the
# backups directory.
escape_dir="$XDG_STATE_HOME/dotfiles/escape"
mkdir -p "$escape_dir"
printf 'create\t%s\t%s\t-\n' \
  "$HOME/traversal-target" "$ROOT/git/.gitconfig" \
  > "$escape_dir/manifest.tsv"

if bash "$ROOT/scripts/backup.sh" restore ../escape >/dev/null 2>&1; then
  printf 'restore accepted a path-traversal backup id\n' >&2
  exit 1
fi
[ -f "$escape_dir/manifest.tsv" ]
[ ! -e "$HOME/traversal-target" ]

# A conflict in a later manifest entry must be detected before any earlier
# entry is mutated.
atomic_id=atomic-preflight
atomic_dir="$XDG_STATE_HOME/dotfiles/backups/$atomic_id"
mkdir -p "$atomic_dir"
first_target="$HOME/first-target"
first_source="$ROOT/git/.gitconfig"
first_backup="$atomic_dir/first.backup"
second_target="$HOME/second-target"
second_source="$ROOT/zsh/.zshrc"
second_backup="$atomic_dir/second.backup"

printf 'first-original\n' > "$first_backup"
printf 'second-original\n' > "$second_backup"
ln -s "$first_source" "$first_target"
printf 'local-conflict\n' > "$second_target"
printf 'replace\t%s\t%s\t%s\nreplace\t%s\t%s\t%s\n' \
  "$first_target" "$first_source" "$first_backup" \
  "$second_target" "$second_source" "$second_backup" \
  > "$atomic_dir/manifest.tsv"

if bash "$ROOT/scripts/backup.sh" restore "$atomic_id" >/dev/null 2>&1; then
  printf 'restore unexpectedly replaced a conflicting path\n' >&2
  exit 1
fi

[ -L "$first_target" ]
[ "$(readlink "$first_target")" = "$first_source" ]
[ -f "$first_backup" ]
[ -f "$atomic_dir/manifest.tsv" ]

printf 'PASS: backup restore contract\n'
