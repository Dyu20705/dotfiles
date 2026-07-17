#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

PROFILE=normal
FORMAT=text

usage() {
  cat <<'EOF'
Usage: bash scripts/doctor.sh [--profile minimal|normal|full] [--json]

Checks commands and deployed links declared in config/workflow.json.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile)
      [ $# -ge 2 ] || die "--profile requires a value"
      PROFILE=$2
      shift 2
      ;;
    --json)
      FORMAT=json
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
validate_profile "$PROFILE"

TMP_RESULTS="$(mktemp)"
trap 'rm -f "$TMP_RESULTS"' EXIT

while IFS=$'\t' read -r name command_name minimum required; do
  path="$(command -v "$command_name" 2>/dev/null || true)"
  if [ -n "$path" ]; then
    status=ok
    version="$(first_version "$command_name")"
  elif [ "$required" = true ]; then
    status=missing
    version=""
  else
    status=optional-missing
    version=""
  fi

  jq -cn \
    --arg type command \
    --arg name "$name" \
    --arg command "$command_name" \
    --arg path "$path" \
    --arg minimum "$minimum" \
    --arg version "$version" \
    --arg status "$status" \
    --argjson required "$required" \
    '{type:$type,name:$name,command:$command,path:$path,minimum:($minimum|select(length>0)),version:$version,required:$required,status:$status}' \
    >> "$TMP_RESULTS"
done < <(
  jq -r --arg profile "$PROFILE" '
    .apps[]
    | [
        .name,
        .command,
        (.minimum // ""),
        ((.required_in | index($profile)) != null)
      ]
    | @tsv
  ' "$DOTFILES_MANIFEST"
)

while IFS=$'\t' read -r source_rel target_raw; do
  source="$DOTFILES_ROOT/$source_rel"
  target="$(expand_home "$target_raw")"
  status=missing
  resolved=""

  if [ -L "$target" ]; then
    resolved="$(readlink "$target" 2>/dev/null || true)"
    if [ "$resolved" = "$source" ]; then
      status=ok
    else
      status=wrong-target
    fi
  elif [ -e "$target" ]; then
    status=not-symlink
  fi

  jq -cn \
    --arg type link \
    --arg source "$source" \
    --arg target "$target" \
    --arg resolved "$resolved" \
    --arg status "$status" \
    '{type:$type,source:$source,target:$target,resolved:$resolved,status:$status}' \
    >> "$TMP_RESULTS"
done < <(
  jq -r --arg profile "$PROFILE" '
    .links[]
    | select(.profiles | index($profile))
    | [.source, .target]
    | @tsv
  ' "$DOTFILES_MANIFEST"
)

REPORT="$({
  jq -s --arg profile "$PROFILE" --arg root "$DOTFILES_ROOT" '
    {
      schema_version: 1,
      profile: $profile,
      root: $root,
      checks: .,
      summary: {
        ok: map(select(.status == "ok")) | length,
        warnings: map(select(.status == "optional-missing" or .status == "not-symlink")) | length,
        failures: map(select(.status == "missing" or .status == "wrong-target")) | length
      }
    }
  ' "$TMP_RESULTS"
})"

if [ "$FORMAT" = json ]; then
  printf '%s\n' "$REPORT"
else
  printf 'Dotfiles doctor\n'
  printf '  profile: %s\n' "$PROFILE"
  printf '  root:    %s\n\n' "$DOTFILES_ROOT"

  printf '%s\n' "$REPORT" | jq -r '
    .checks[]
    | if .type == "command" then
        "[\(.status)] command \(.name): \(.path // "") \(.version // "")"
      else
        "[\(.status)] link \(.target) -> \(.source)"
      end
  '

  printf '\n'
  printf '%s\n' "$REPORT" | jq -r '"Summary: \(.summary.ok) ok, \(.summary.warnings) warnings, \(.summary.failures) failures"'
fi

failures="$(printf '%s\n' "$REPORT" | jq -r '.summary.failures')"
[ "$failures" -eq 0 ]
