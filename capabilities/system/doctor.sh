#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
jq -e '.id == "system" and (.expected_startup_cost_ms | type == "number")' "$ROOT/manifest.json" >/dev/null
missing=()
for command in lsof strace btop ncdu; do command -v "$command" >/dev/null 2>&1 || missing+=("$command"); done
if [ "${#missing[@]}" -gt 0 ]; then printf 'system capability usable; optional tools missing: %s\n' "${missing[*]}"; else printf 'system capability ready\n'; fi
