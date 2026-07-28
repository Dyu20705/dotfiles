#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/common.sh"

PROFILE=normal
DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: packages.sh [--profile minimal|normal|full] [--dry-run] [--yes]

Installs Ubuntu packages declared for a profile. Package installation is kept
separate from symlink deployment. Use --dry-run to print the exact transaction.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) [ $# -ge 2 ] || die "--profile requires a value" 20; PROFILE=$2; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" 20 ;;
  esac
done

validate_manifest || die "manifest validation failed"
validate_profile "$PROFILE"
mapfile -t packages < <(jq -r --arg profile "$PROFILE" '.packages[$profile][]' "$DOTFILES_MANIFEST")
[ "${#packages[@]}" -gt 0 ] || exit 0

quoted=()
for package in "${packages[@]}"; do
  printf -v q '%q' "$package"
  quoted+=("$q")
done

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'sudo apt-get update && sudo apt-get install -y %s\n' "${quoted[*]}"
  exit 0
fi

[ "$(uname -s)" = Linux ] || die "package installation supports Ubuntu only"
has_cmd apt-get || die "apt-get is required"
if [ "$(id -u)" -eq 0 ]; then
  apt-get update
  if [ "$ASSUME_YES" -eq 1 ]; then apt-get install -y "${packages[@]}"; else apt-get install "${packages[@]}"; fi
else
  require_cmd sudo
  sudo apt-get update
  if [ "$ASSUME_YES" -eq 1 ]; then sudo apt-get install -y "${packages[@]}"; else sudo apt-get install "${packages[@]}"; fi
fi
