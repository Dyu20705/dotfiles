#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/context.sh
. "$SCRIPT_DIR/lib/context.sh"

PROFILE=normal
FORMAT=text
EXPLAIN=0

usage() {
  cat <<'EOF'
Usage: doctor.sh [--profile minimal|normal|full] [--json] [--explain]

Checks commands, deployed links, private Git identity, tmux plugins and selected
capability packs. --explain prints remediation for degraded checks.
EOF
}

version_ge() {
  awk -v actual="$1" -v minimum="$2" 'BEGIN {
    split(actual,a,"."); split(minimum,m,".")
    for (i=1;i<=4;i++) {
      av=(a[i]==""?0:a[i]+0); mv=(m[i]==""?0:m[i]+0)
      if (av>mv) exit 0; if (av<mv) exit 1
    }
    exit 0
  }'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) [ $# -ge 2 ] || die "--profile requires a value" 20; PROFILE=$2; shift 2 ;;
    --json) FORMAT=json; shift ;;
    --explain) EXPLAIN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" 20 ;;
  esac
done

require_cmd jq
validate_manifest || die "manifest validation failed: $DOTFILES_MANIFEST"
validate_profile "$PROFILE"
CONTEXT=$(dotfiles_detect_context)
TMP_RESULTS=$(mktemp)
trap 'rm -f "$TMP_RESULTS"' EXIT

while IFS=$'\034' read -r name command_name minimum required; do
  path=$(command -v "$command_name" 2>/dev/null || true)
  version=""; detected_version=""; remediation=""
  if [ -n "$path" ]; then
    version=$(first_version "$command_name")
    detected_version=$(printf '%s\n' "$version" | grep -Eo '[0-9]+([.][0-9]+){1,3}' | head -n 1 || true)
    status=ok
    if [ -n "$minimum" ]; then
      if [ -z "$detected_version" ]; then status=version-unknown
      elif ! version_ge "$detected_version" "$minimum"; then status=outdated; fi
    fi
  elif [ "$required" = true ]; then status=missing
  else status=optional-missing
  fi
  if [ "$status" != ok ]; then remediation="dot packages --profile $PROFILE --dry-run"; fi
  jq -cn --arg type command --arg name "$name" --arg command "$command_name" \
    --arg path "$path" --arg minimum "$minimum" --arg version "$version" \
    --arg detected_version "$detected_version" --arg status "$status" \
    --arg remediation "$remediation" --argjson required "$required" \
    '{type:$type,name:$name,command:$command,path:$path,minimum:(if $minimum=="" then null else $minimum end),version:$version,detected_version:(if $detected_version=="" then null else $detected_version end),required:$required,status:$status,remediation:$remediation}' >> "$TMP_RESULTS"
done < <(jq -r --arg profile "$PROFILE" '.apps[] | [.name,.command,(.minimum // ""),(((.required_in | index($profile)) != null)|tostring)] | join("\u001c")' "$DOTFILES_MANIFEST")

while IFS=$'\t' read -r source_rel target_raw; do
  source="$DOTFILES_ROOT/$source_rel"; target=$(expand_home "$target_raw"); status=missing; resolved=""
  if [ ! -e "$source" ]; then status=source-missing
  elif [ -L "$target" ]; then resolved=$(readlink "$target" 2>/dev/null || true); if [ "$resolved" = "$source" ]; then status=ok; else status=wrong-target; fi
  elif [ -e "$target" ]; then status=not-symlink
  fi
  jq -cn --arg type link --arg source "$source" --arg target "$target" --arg resolved "$resolved" --arg status "$status" \
    --arg remediation "dot link --profile $PROFILE" \
    '{type:$type,source:$source,target:$target,resolved:$resolved,status:$status,required:true,remediation:(if $status=="ok" then "" else $remediation end)}' >> "$TMP_RESULTS"
done < <(jq -r --arg profile "$PROFILE" '.links[] | select(.profiles | index($profile)) | [.source,.target] | @tsv' "$DOTFILES_MANIFEST")

GIT_LOCAL="$HOME/.gitconfig.local"
if [ -r "$GIT_LOCAL" ]; then status=ok; else status=optional-missing; fi
jq -cn --arg type local-config --arg name git-identity --arg path "$GIT_LOCAL" --arg status "$status" \
  '{type:$type,name:$name,path:$path,status:$status,required:false,remediation:(if $status=="ok" then "" else "copy git/.gitconfig.local.example to ~/.gitconfig.local" end)}' >> "$TMP_RESULTS"

TPM="$HOME/.tmux/plugins/tpm/tpm"
if [ "$PROFILE" = minimal ]; then status=disabled
elif [ -x "$TPM" ]; then status=ok
else status=optional-missing
fi
jq -cn --arg type integration --arg name tpm --arg path "$TPM" --arg status "$status" \
  '{type:$type,name:$name,path:$path,status:$status,required:false,remediation:(if $status=="optional-missing" then "bash scripts/install-tmux-plugins.sh --install" else "" end)}' >> "$TMP_RESULTS"

while IFS= read -r capability; do
  [ -n "$capability" ] || continue
  if ! dotfiles_capability_known "$capability"; then status=invalid
  elif [ "$PROFILE" = minimal ]; then status=disabled
  elif bash "$DOTFILES_ROOT/capabilities/$capability/doctor.sh" >/dev/null 2>&1; then status=ok
  else status=degraded
  fi
  jq -cn --arg type capability --arg name "$capability" --arg status "$status" \
    '{type:$type,name:$name,status:$status,required:false,remediation:(if $status=="invalid" then "dot capability disable " + $name elif $status=="degraded" then "dot capability doctor " + $name else "" end)}' >> "$TMP_RESULTS"
done < <(dotfiles_selected_capabilities)

REPORT=$(jq -s --arg profile "$PROFILE" --arg context "$CONTEXT" --arg root "$DOTFILES_ROOT" '
  {schema_version:1,profile:$profile,context:$context,root:$root,checks:.,summary:{
    ok:(map(select(.status=="ok" or .status=="disabled"))|length),
    warnings:(map(select(.status=="optional-missing" or .status=="degraded" or (.status=="version-unknown" and .required==false)))|length),
    failures:(map(select(.status=="missing" or .status=="wrong-target" or .status=="not-symlink" or .status=="outdated" or .status=="source-missing" or .status=="invalid" or (.status=="version-unknown" and .required==true)))|length)
  }}' "$TMP_RESULTS")

if [ "$FORMAT" = json ]; then
  printf '%s\n' "$REPORT"
else
  printf 'Dotfiles doctor\n  profile: %s\n  context: %s\n  root:    %s\n\n' "$PROFILE" "$CONTEXT" "$DOTFILES_ROOT"
  printf '%s\n' "$REPORT" | jq -r '.checks[] | if .type=="command" then "[\(.status)] command \(.name): \(.path // "") \(.version // "")" elif .type=="link" then "[\(.status)] link \(.target) -> \(.source)" else "[\(.status)] \(.type) \(.name // .path // "")" end'
  if [ "$EXPLAIN" -eq 1 ]; then
    printf '\nRemediation:\n'
    printf '%s\n' "$REPORT" | jq -r '.checks[] | select(.status!="ok" and .status!="disabled" and (.remediation // "")!="") | "- \(.type) \(.name // .target // ""): \(.remediation)"'
  fi
  printf '\n'
  printf '%s\n' "$REPORT" | jq -r '"Summary: \(.summary.ok) ok, \(.summary.warnings) warnings, \(.summary.failures) failures"'
fi
failures=$(printf '%s\n' "$REPORT" | jq -r '.summary.failures')
[ "$failures" -eq 0 ]
