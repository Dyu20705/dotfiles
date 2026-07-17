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

Creates safe symlinks described by config/workflow.json. Existing paths are moved
under ${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups before replacement.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile)
      [ $# -ge 2 ] || die "--profile requires a value"
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
      die "unknown argument: $1"
      ;;
  esac
done

require_cmd jq
validate_manifest || die "manifest validation failed: $DOTFILES_MANIFEST"
validate_profile "$PROFILE"

info "root: $DOTFILES_ROOT"
info "profile: $PROFILE"

TMP_LINKS=$(mktemp)
trap 'rm -f "$TMP_LINKS"' EXIT

if ! jq -r --arg profile "$PROFILE" '
  .links[]
  | select(.profiles | index($profile))
  | [.source, .target]
  | @tsv
' "$DOTFILES_MANIFEST" > "$TMP_LINKS"; then
  die "failed to read links for profile: $PROFILE"
fi

# Validate every source and target before changing the user's home directory.
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

if [ "$DRY_RUN" -eq 0 ] && [ -z "${DOTFILES_BACKUP_ROOT:-}" ]; then
  DOTFILES_BACKUP_ROOT="$(xdg_state_home)/dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
fi

while IFS=$'\t' read -r source_rel target_raw; do
  [ -n "$source_rel" ] || continue
  source="$DOTFILES_ROOT/$source_rel"
  target=$(expand_home "$target_raw")
  link_path "$source" "$target" "$DRY_RUN"
done < "$TMP_LINKS"

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$(xdg_cache_home)/dotfiles/tmux" "$(xdg_state_home)/dotfiles/tmux/sessions"
fi

cat <<EOF

Bootstrap complete.

Next steps:
  1. Create ~/.gitconfig.local from git/.gitconfig.local.example.
  2. Run: bash "$DOTFILES_ROOT/scripts/doctor.sh" --profile "$PROFILE"
  3. Run: bash "$DOTFILES_ROOT/scripts/test.sh" --profile runtime
EOF
