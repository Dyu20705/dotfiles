#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/common.sh"
PROFILE=normal
DRY_RUN=0
usage() {
  cat <<'EOF'
Usage: uninstall.sh [--profile minimal|normal|full] [--dry-run]

Removes only symlinks whose target exactly matches the current manifest source.
EOF
}
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) [ $# -ge 2 ] || die "--profile requires a value" 20; PROFILE=$2; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" 20 ;;
  esac
done
validate_manifest || die "manifest validation failed"
validate_profile "$PROFILE"
while IFS=$'\t' read -r source_rel target_raw; do
  source="$DOTFILES_ROOT/$source_rel"
  target=$(expand_home "$target_raw")
  if [ -L "$target" ] && [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then info "would remove $target"; else rm "$target"; info "removed $target"; fi
  elif [ -e "$target" ] || [ -L "$target" ]; then
    warn "left unmanaged path unchanged: $target"
  fi
done < <(jq -r --arg profile "$PROFILE" '.links[] | select(.profiles | index($profile)) | [.source,.target] | @tsv' "$DOTFILES_MANIFEST")
