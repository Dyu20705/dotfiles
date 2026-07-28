#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

required=(
  shell/common.sh
  config/local.example
  tmux/local.conf.example
  nvim/.config/nvim/lua/local.lua.example
  wezterm/local.lua.example
  docs/NEOVIM_PLUGINS.md
  docs/KEYMAPS.md
  docs/GIT_WORKFLOW.md
  docs/BENCHMARKS.md
  docs/SECURITY.md
  docs/RELEASE_EVIDENCE.md
  CHANGELOG.md
  mise.toml
  .github/workflows/clean-room.yml
  .github/workflows/security.yml
  .github/workflows/benchmarks.yml
  .github/workflows/update-dependencies.yml
)
for path in "${required[@]}"; do
  [ -e "$ROOT/$path" ] || {
    printf 'missing extended v0 file: %s\n' "$path" >&2
    exit 1
  }
done

if git config --file "$ROOT/git/.gitconfig" --get user.name >/dev/null 2>&1; then exit 1; fi
if git config --file "$ROOT/git/.gitconfig" --get user.email >/dev/null 2>&1; then exit 1; fi
# shellcheck disable=SC2088
[ "$(git config --file "$ROOT/git/.gitconfig" --get include.path)" = "~/.gitconfig.local" ]

while IFS= read -r workflow; do
  if grep -En '^[[:space:]]*- uses: [^#[:space:]]+@(v[0-9]+|main|master|latest)([[:space:]]|$)' "$workflow"; then
    printf 'mutable action reference in %s\n' "$workflow" >&2
    exit 1
  fi
done < <(find "$ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print)

mkdir -p "$TMP/home" "$TMP/bin"
cat > "$TMP/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo must not run during dry-run\n' >&2
exit 99
EOF
chmod +x "$TMP/bin/sudo"
package_output=$(HOME="$TMP/home" PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/packages.sh" --profile normal --dry-run)
printf '%s\n' "$package_output" | grep -F 'apt-get install' >/dev/null
printf '%s\n' "$package_output" | grep -E 'tmux|neovim' >/dev/null

export HOME="$TMP/uninstall-home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$HOME" "$TMP/unrelated"
ln -s "$TMP/unrelated" "$HOME/unrelated-link"
bash "$ROOT/scripts/bootstrap.sh" --profile minimal >/dev/null
bash "$ROOT/scripts/uninstall.sh" --profile minimal >/dev/null
[ ! -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]
[ -L "$HOME/unrelated-link" ]

SSH_CONNECTION='client 1 server 2' DOTFILES_PROFILE=normal \
  HOME="$TMP/context-home" XDG_CONFIG_HOME="$TMP/context-config" \
  bash "$ROOT/scripts/dot" env --json \
  | jq -e '.context == "remote" and .profile == "minimal"' >/dev/null

HOME="$TMP/bench-home" XDG_CACHE_HOME="$TMP/bench-cache" \
  bash "$ROOT/scripts/benchmark.sh" --json \
  | jq -e 'type == "array" and length >= 2 and all(.[]; (.median_ms | type == "number") and (.budget_ms | type == "number"))' >/dev/null

set +e
HOME="$TMP/tpm-home" bash "$ROOT/scripts/install-tmux-plugins.sh" --check >/dev/null 2>&1
status=$?
set -e
[ "$status" -eq 0 ] || [ "$status" -eq 10 ]
[ ! -e "$TMP/tpm-home/.tmux/plugins/tpm" ]

grep -F 'dot doctor' "$ROOT/docs/CHEATSHEET.md" >/dev/null
grep -F 'dev --list' "$ROOT/docs/CHEATSHEET.md" >/dev/null
grep -F 'gw new' "$ROOT/docs/CHEATSHEET.md" >/dev/null
grep -F 'Ctrl+A' "$ROOT/docs/KEYMAPS.md" >/dev/null
grep -F '<leader>f' "$ROOT/docs/KEYMAPS.md" >/dev/null

if grep -Eq 'image:.*(:latest|:-latest)' "$ROOT/docker-compose.yaml"; then exit 1; fi
printf 'PASS: extended v0 contracts\n'
