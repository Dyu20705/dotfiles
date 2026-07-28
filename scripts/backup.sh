#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
BACKUP_BASE="$(xdg_state_home)/dotfiles/backups"

usage() { cat <<'EOF'
Usage:
  backup.sh list [--json]
  backup.sh restore <id> [--force]
EOF
}

list_backups() {
  local format=${1:-text} dir first=1
  [ "$format" = json ] && printf '['
  if [ -d "$BACKUP_BASE" ]; then
    while IFS= read -r dir; do
      [ -f "$dir/metadata.json" ] || continue
      if [ "$format" = json ]; then
        [ "$first" -eq 1 ] || printf ','
        jq -c --argjson entries "$(wc -l < "$dir/manifest.tsv" 2>/dev/null || printf 0)" '. + {entries:$entries}' "$dir/metadata.json"
        first=0
      else
        jq -r '"\(.id)\t\(.created_at)\t\(.profile)"' "$dir/metadata.json"
      fi
    done < <(find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d -print | sort -r)
  fi
  [ "$format" = json ] && printf ']\n'
}

restore_backup() {
  local id=$1 force=${2:-0} dir="$BACKUP_BASE/$1" manifest="$BACKUP_BASE/$1/manifest.tsv"
  local operation target source backup conflict
  [ -f "$manifest" ] || die "backup not found or incomplete: $id" 20
  while IFS=$'\t' read -r operation target source backup; do
    [ -n "$target" ] || continue
    case "$target" in "$HOME"/*) ;; *) die "backup target outside HOME: $target" ;; esac
    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ] && [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then
        rm "$target"
      elif [ "$force" -eq 1 ]; then
        conflict="$target.pre-restore-$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$conflict"
        warn "moved current path to $conflict"
      else
        die "refusing to replace changed path: $target (use --force)" 30
      fi
    fi
    case "$operation" in
      create) info "removed managed link: $target" ;;
      replace)
        [ -e "$backup" ] || [ -L "$backup" ] || die "recorded backup is missing: $backup"
        mkdir -p "$(dirname "$target")"
        mv "$backup" "$target"
        info "restored $target"
        ;;
      *) die "unknown backup operation: $operation" ;;
    esac
  done < "$manifest"
  mv "$dir" "$dir.restored-$(date +%Y%m%d-%H%M%S)"
}

[ $# -gt 0 ] || { usage; exit 20; }
case "$1" in
  list) shift; if [ "${1:-}" = --json ]; then list_backups json; else list_backups text; fi ;;
  restore) [ $# -ge 2 ] || die "restore requires a backup id" 20; force=0; [ "${3:-}" = --force ] && force=1; restore_backup "$2" "$force" ;;
  -h|--help) usage ;;
  *) die "unknown backup command: $1" 20 ;;
esac
