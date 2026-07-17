#!/usr/bin/env bash
set -euo pipefail

[ $# -ge 1 ] || { printf 'Usage: dotfiles-open <path-or-url>\n' >&2; exit 2; }
target=$1

if command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$target"
elif command -v open >/dev/null 2>&1; then
  exec open "$target"
elif command -v wslview >/dev/null 2>&1; then
  exec wslview "$target"
elif command -v cmd.exe >/dev/null 2>&1; then
  exec cmd.exe /c start "" "$target"
else
  printf 'No supported opener found for: %s\n' "$target" >&2
  exit 1
fi
