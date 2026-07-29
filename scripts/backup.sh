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

validate_backup_id() {
  local id=$1
  case "$id" in
    ""|.|..|*/*|*\\*|*[!A-Za-z0-9._-]*)
      die "invalid backup id: $id" 20
      ;;
  esac
}

preflight_restore() {
  local dir=$1 manifest=$2 force=$3
  local operation target source backup

  while IFS=$'\t' read -r operation target source backup; do
    [ -n "$target" ] || continue

    case "$operation" in
      create|replace) ;;
      *) die "unknown backup operation: $operation" 20 ;;
    esac

    case "$target" in
      "$HOME"/*) ;;
      *) die "backup target outside HOME: $target" 20 ;;
    esac

    [ -n "$source" ] || die "backup source is empty for target: $target" 20

    if [ "$operation" = replace ]; then
      case "$backup" in
        "$dir"/*) ;;
        *) die "recorded backup is outside its run directory: $backup" 20 ;;
      esac
      [ -e "$backup" ] || [ -L "$backup" ] \
        || die "recorded backup is missing: $backup" 30
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ] \
        && [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then
        :
      elif [ "$force" -ne 1 ]; then
        die "refusing to replace changed path: $target (use --force)" 30
      fi
    fi
  done < "$manifest"
}

restore_backup() {
  local id=$1 force=${2:-0}
  local dir manifest operation target source backup conflict restored_dir

  validate_backup_id "$id"
  dir="$BACKUP_BASE/$id"
  manifest="$dir/manifest.tsv"
  [ -f "$manifest" ] || die "backup not found or incomplete: $id" 20

  # Validate the entire manifest and all known conflicts before mutating HOME.
  preflight_restore "$dir" "$manifest" "$force"

  while IFS=$'\t' read -r operation target source backup; do
    [ -n "$target" ] || continue

    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ] \
        && [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then
        rm "$target"
      elif [ "$force" -eq 1 ]; then
        conflict="$target.pre-restore-$(date +%Y%m%d-%H%M%S)-$$"
        mv "$target" "$conflict"
        warn "moved current path to $conflict"
      else
        die "restore state changed after preflight: $target" 30
      fi
    fi

    case "$operation" in
      create)
        info "removed managed link: $target"
        ;;
      replace)
        mkdir -p "$(dirname "$target")"
        mv "$backup" "$target"
        info "restored $target"
        ;;
    esac
  done < "$manifest"

  restored_dir="$dir.restored-$(date +%Y%m%d-%H%M%S)-$$"
  mv "$dir" "$restored_dir"
}

[ $# -gt 0 ] || { usage; exit 20; }
case "$1" in
  list)
    shift
    if [ "${1:-}" = --json ]; then list_backups json; else list_backups text; fi
    ;;
  restore)
    [ $# -ge 2 ] || die "restore requires a backup id" 20
    force=0
    [ "${3:-}" = --force ] && force=1
    restore_backup "$2" "$force"
    ;;
  -h|--help) usage ;;
  *) die "unknown backup command: $1" 20 ;;
esac
