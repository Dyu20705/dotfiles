#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

PROFILE=normal
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: bash scripts/bootstrap.sh [--profile minimal|normal|full] [--dry-run]

Creates safe symlinks described by config/workflow.json. Existing paths are
moved under the XDG state directory and recorded in a restorable manifest.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile)
      [ $# -ge 2 ] || die "--profile requires a value" "$DOTFILES_EXIT_USAGE"
      PROFILE=$2
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1" "$DOTFILES_EXIT_USAGE"
      ;;
  esac
done

require_cmd jq
validate_manifest || die "manifest validation failed: $DOTFILES_MANIFEST"
validate_profile "$PROFILE"

info "root: $DOTFILES_ROOT"
info "profile: $PROFILE"

TMP_LINKS=$(mktemp)
BACKUP_RUN=""
cleanup() {
  rm -f "$TMP_LINKS"
  if [ -n "$BACKUP_RUN" ] && [ -d "$BACKUP_RUN" ] \
    && [ ! -s "$BACKUP_RUN/manifest.tsv" ]; then
    rm -rf "$BACKUP_RUN"
  fi
}
trap cleanup EXIT

jq -r --arg profile "$PROFILE" '
  .links[]
  | select(.profiles | index($profile))
  | [.source, .target]
  | @tsv
' "$DOTFILES_MANIFEST" > "$TMP_LINKS" \
  || die "failed to read links for profile: $PROFILE"

while IFS=$'\t' read -r source_rel target_raw; do
  [ -n "$source_rel" ] || continue
  source="$DOTFILES_ROOT/$source_rel"
  target=$(expand_home "$target_raw")
  [ -e "$source" ] || die "manifest source does not exist: $source"
  case "$target" in
    "$HOME"/*) ;;
    *) die "manifest target is outside HOME: $target" ;;
  esac
done < "$TMP_LINKS"

if [ "$DRY_RUN" -eq 0 ]; then
  run_id="$(date +%Y%m%d-%H%M%S)-$$"
  BACKUP_RUN="$(xdg_state_home)/dotfiles/backups/$run_id"
  mkdir -p "$BACKUP_RUN"
  : > "$BACKUP_RUN/manifest.tsv"
  jq -n \
    --arg id "$run_id" \
    --arg profile "$PROFILE" \
    --arg root "$DOTFILES_ROOT" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{id:$id,profile:$profile,root:$root,created_at:$created_at}' \
    > "$BACKUP_RUN/metadata.json"
  DOTFILES_BACKUP_ROOT="$BACKUP_RUN"
  DOTFILES_BACKUP_MANIFEST="$BACKUP_RUN/manifest.tsv"
  export DOTFILES_BACKUP_ROOT DOTFILES_BACKUP_MANIFEST
fi

while IFS=$'\t' read -r source_rel target_raw; do
  [ -n "$source_rel" ] || continue
  source="$DOTFILES_ROOT/$source_rel"
  target=$(expand_home "$target_raw")
  link_path "$source" "$target" "$DRY_RUN"
done < "$TMP_LINKS"

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p \
    "$(xdg_cache_home)/dotfiles/tmux" \
    "$(xdg_state_home)/dotfiles/tmux/sessions"
fi

cat <<EOF

Bootstrap complete.

Next steps:
  1. Create ~/.gitconfig.local from git/.gitconfig.local.example.
  2. Run: "$DOTFILES_ROOT/scripts/dot" doctor --profile "$PROFILE"
  3. Run: "$DOTFILES_ROOT/scripts/dot" check runtime
EOF
