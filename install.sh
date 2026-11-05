#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--dry-run]

Create symlinks for Kitty, tmux and Neovim. Existing configurations are moved
aside to a timestamped backup before a symlink is created.
USAGE
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

link_config() {
  local source="$1"
  local target="$2"
  local current backup

  if [[ ! -e "$source" ]]; then
    printf 'Missing source: %s\n' "$source" >&2
    return 1
  fi

  if [[ -L "$target" ]]; then
    current="$(readlink -f -- "$target" 2>/dev/null || true)"
    if [[ "$current" == "$source" ]]; then
      printf 'Already linked: %s\n' "$target"
      return 0
    fi
  fi

  if ((DRY_RUN)); then
    printf 'Would link: %s -> %s\n' "$target" "$source"
    if [[ -e "$target" || -L "$target" ]]; then
      printf '  Existing target would be backed up.\n'
    fi
    return 0
  fi

  mkdir -p -- "$(dirname -- "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    backup="${target}.backup.$(date '+%Y%m%d-%H%M%S')-$$"
    mv -- "$target" "$backup"
    printf 'Backup: %s\n' "$backup"
  fi

  ln -s -- "$source" "$target"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

# Validate all repository paths before changing the home directory.
for source in \
  "$ROOT/kitty/kitty.conf" \
  "$ROOT/tmux/tmux.conf" \
  "$ROOT/nvim/.config/nvim/init.lua"; do
  [[ -f "$source" ]] || { printf 'Missing config: %s\n' "$source" >&2; exit 1; }
done

link_config "$ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_config "$ROOT/tmux/tmux.conf" "$HOME/.tmux.conf"
link_config "$ROOT/nvim/.config/nvim" "$HOME/.config/nvim"

if ((DRY_RUN)); then
  printf '\nDry run complete; no files were changed.\n'
else
  printf '\nDone. Open Kitty, then start tmux or Neovim.\n'
fi
