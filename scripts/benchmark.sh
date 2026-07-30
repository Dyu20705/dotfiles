#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

FORMAT=text
if [ "${1:-}" = -h ] || [ "${1:-}" = --help ]; then
  printf 'Usage: benchmark.sh [--json]\n'
  exit 0
fi
[ "${1:-}" = --json ] && FORMAT=json

measure() {
  python3 - "$@" <<'PY'
import statistics
import subprocess
import sys
import time

samples = []
for _ in range(3):
    start = time.perf_counter()
    subprocess.run(
        sys.argv[1:],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    samples.append((time.perf_counter() - start) * 1000)

print(round(statistics.median(samples), 3))
PY
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

add_metric() {
  local metric=$1 budget=$2 value status=ok
  shift 2
  value=$(measure "$@")
  if awk -v v="$value" -v b="$budget" \
    'BEGIN { exit !(v > b) }'; then
    status=over-budget
  fi
  jq -cn \
    --arg metric "$metric" \
    --argjson median "$value" \
    --argjson budget "$budget" \
    --arg status "$status" \
    '{metric:$metric,samples:3,median_ms:$median,budget_ms:$budget,status:$status}' \
    >> "$tmp"
}

require_cmd python3
validate_manifest || die "manifest validation failed"

add_metric git \
  "$(jq '.performance_budgets_ms.git' "$DOTFILES_MANIFEST")" \
  git --version

if has_cmd zsh; then
  add_metric zsh \
    "$(jq '.performance_budgets_ms.zsh' "$DOTFILES_MANIFEST")" \
    zsh -d -f -c exit
fi

if has_cmd nvim; then
  add_metric nvim \
    "$(jq '.performance_budgets_ms.nvim' "$DOTFILES_MANIFEST")" \
    nvim --headless --clean +qa
fi

report=$(jq -s '.' "$tmp")
if [ "$FORMAT" = json ]; then
  printf '%s\n' "$report"
else
  printf '%s\n' "$report" \
    | jq -r '.[] | "\(.metric): \(.median_ms) ms / \(.budget_ms) ms [\(.status)]"'
fi
