#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}

required=(
  scripts/dot
  scripts/dev
  scripts/gw
  scripts/packages.sh
  scripts/backup.sh
  scripts/uninstall.sh
  scripts/benchmark.sh
  scripts/install-tmux-plugins.sh
  completions/dot.bash
  completions/_dot
  completions/dev.bash
  completions/_dev
  completions/gw.bash
  completions/_gw
  capabilities/system/manifest.json
  docs/CHEATSHEET.md
  docs/ARCHITECTURE.md
)

for path in "${required[@]}"; do
  [ -e "$ROOT/$path" ] || {
    printf 'missing v0 contract file: %s\n' "$path" >&2
    exit 1
  }
done

for command in dot dev gw; do
  bash "$ROOT/scripts/$command" --help >/dev/null
 done

for script in packages.sh backup.sh uninstall.sh benchmark.sh install-tmux-plugins.sh; do
  bash "$ROOT/scripts/$script" --help >/dev/null
 done

jq -e '
  (.contexts | type == "object" and has("desktop") and has("remote"))
  and (.packages | type == "object" and has("minimal") and has("normal") and has("full"))
  and (.commands | type == "array" and index("dot") != null and index("dev") != null and index("gw") != null)
  and (.performance_budgets_ms | type == "object")
  and (.capability_packs | type == "array" and index("system") != null)
' "$ROOT/config/workflow.json" >/dev/null

printf 'PASS: v0 file and manifest contract\n'
