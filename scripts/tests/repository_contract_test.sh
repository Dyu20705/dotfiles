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
  scripts/check-whitespace.sh
  scripts/install-tmux-plugins.sh
  scripts/security-check.sh
  scripts/test-contracts.sh
  zsh/.zshrc
  zsh/common.zsh
  completions/_dot
  completions/_dev
  completions/_gw
  capabilities/system/manifest.json
  CONTRIBUTING.md
  docs/CHEATSHEET.md
  docs/ARCHITECTURE.md
  docs/MAINTENANCE.md
  docs/SECURITY.md
  docs/TROUBLESHOOTING.md
)

for path in "${required[@]}"; do
  [ -e "$ROOT/$path" ] || {
    printf 'missing repository contract file: %s\n' "$path" >&2
    exit 1
  }
done

for command in dot dev gw; do
  bash "$ROOT/scripts/$command" --help >/dev/null
done

for script in \
  packages.sh backup.sh uninstall.sh benchmark.sh install-tmux-plugins.sh
do
  bash "$ROOT/scripts/$script" --help >/dev/null
done

jq -e '
  (.contexts | type == "object" and has("desktop") and has("remote"))
  and (.packages | type == "object" and has("minimal") and has("normal") and has("full"))
  and (.commands | type == "array"
    and index("dot") != null
    and index("dev") != null
    and index("gw") != null)
  and (.performance_budgets_ms | type == "object"
    and has("git")
    and has("zsh")
    and (has("bash") | not))
  and (.capability_packs | type == "array" and index("system") != null)
  and (all(.links[]; (.source | startswith("bash/") | not)))
  and (all(.links[]; (.source | endswith(".bash") | not)))
  and (any(.links[];
    .source == "zsh/.zshrc"
    and .profiles == ["normal", "full"]))
' "$ROOT/config/workflow.json" >/dev/null

printf 'PASS: repository file and manifest contract\n'
