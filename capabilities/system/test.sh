#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bash -n "$ROOT/doctor.sh"
jq -e '.id == "system"' "$ROOT/manifest.json" >/dev/null
grep -F 'sysdisk()' "$ROOT/shell.sh" >/dev/null
printf 'PASS: system capability\n'
