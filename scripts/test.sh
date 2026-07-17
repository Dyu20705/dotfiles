#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

PROFILE=full
FAILURES=0
SKIPS=0

usage() {
  cat <<'EOF'
Usage: bash scripts/test.sh [--profile static|runtime|full]

static   syntax, lint and configuration checks
runtime  isolated startup smoke tests for installed applications
full     static and runtime checks
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile)
      [ $# -ge 2 ] || die "--profile requires a value"
      PROFILE=$2
      shift 2
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

case "$PROFILE" in
  static|runtime|full) ;;
  *) die "unknown test profile: $PROFILE" ;;
esac

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; FAILURES=$((FAILURES + 1)); }
skip() { printf '[SKIP] %s\n' "$1"; SKIPS=$((SKIPS + 1)); }

run_check() {
  local name=$1
  shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

bash_dotfiles() {
  printf '%s\0' \
    "$DOTFILES_ROOT/bash/.bashrc" \
    "$DOTFILES_ROOT/bash/.bash_profile" \
    "$DOTFILES_ROOT/bash/.profile" \
    "$DOTFILES_ROOT/bash/.bash_env" \
    "$DOTFILES_ROOT/bash/.bash_aliases"
}

shell_scripts() {
  find "$DOTFILES_ROOT/git" "$DOTFILES_ROOT/tmux" "$DOTFILES_ROOT/scripts" \
    -type f -name '*.sh' -print0
}

shell_files() {
  bash_dotfiles
  shell_scripts
}

check_bash_syntax() {
  local files=()
  while IFS= read -r -d '' file; do files+=("$file"); done < <(shell_files)
  bash -n "${files[@]}"
}

check_shellcheck() {
  if ! has_cmd shellcheck; then
    skip "ShellCheck not installed"
    return 0
  fi

  local dotfiles=() scripts=()
  while IFS= read -r -d '' file; do dotfiles+=("$file"); done < <(bash_dotfiles)
  while IFS= read -r -d '' file; do scripts+=("$file"); done < <(shell_scripts)

  shellcheck -x --shell=bash "${dotfiles[@]}" || return 1
  shellcheck -x "${scripts[@]}"
}

check_zsh_syntax() {
  if ! has_cmd zsh; then
    skip "Zsh not installed"
    return 0
  fi
  zsh -n "$DOTFILES_ROOT/zsh/.zshrc"
}

check_lua_syntax() {
  local lua_parser=""
  if has_cmd luac5.4; then
    lua_parser=luac5.4
  elif has_cmd luac; then
    lua_parser=luac
  else
    skip "Lua parser not installed"
    return 0
  fi

  while IFS= read -r -d '' file; do
    "$lua_parser" -p "$file" || return 1
  done < <(find "$DOTFILES_ROOT/nvim" "$DOTFILES_ROOT/wezterm" -type f -name '*.lua' -print0)
}

check_json() {
  has_cmd jq || return 1
  jq -e '.schema_version == 1 and (.profiles | type == "object") and (.links | type == "array")' \
    "$DOTFILES_ROOT/config/workflow.json" >/dev/null
}

check_yaml() {
  if ! has_cmd yamllint; then
    skip "yamllint not installed"
    return 0
  fi
  yamllint -d relaxed \
    "$DOTFILES_ROOT/docker-compose.yaml" \
    "$DOTFILES_ROOT/lazygit/config.yml" \
    "$DOTFILES_ROOT/.github/workflows/validate.yml"
}

check_compose() {
  if ! has_cmd docker || ! docker compose version >/dev/null 2>&1; then
    skip "Docker Compose v2 not installed"
    return 0
  fi
  docker compose -f "$DOTFILES_ROOT/docker-compose.yaml" config --quiet
}

check_hardcoded_paths() {
  local matches
  matches="$(git -C "$DOTFILES_ROOT" grep -nE '(\$HOME/dotfiles|~/dotfiles|/home/[^/]+/|Documents/git)' -- \
    ':!README.md' ':!docs/**' ':!scripts/test.sh' 2>/dev/null || true)"
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" >&2
    return 1
  fi
}

check_keymap_contract() {
  local test_file_count
  test_file_count=$(grep -RhoE "['\"]<leader>tf['\"]" "$DOTFILES_ROOT/nvim/.config/nvim/lua" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$test_file_count" -gt 1 ]; then
    printf '<leader>tf is declared %s times\n' "$test_file_count" >&2
    return 1
  fi

  if grep -RqsE '^bind(-key)?[[:space:]]+-n[[:space:]]+C-v' "$DOTFILES_ROOT/tmux"; then
    printf 'tmux must not steal Ctrl+V from applications\n' >&2
    return 1
  fi

  if grep -qE 'key[[:space:]]*=[[:space:]]*"F(5|6|7|8|9|10|11|12)"[^\n]*mods[[:space:]]*=[[:space:]]*""' \
    "$DOTFILES_ROOT/wezterm/.wezterm.lua"; then
    printf 'WezTerm contains an unmodified application function-key binding\n' >&2
    return 1
  fi
}

bash_runtime() {
  local tmp_home
  tmp_home=$(mktemp -d)
  HOME="$tmp_home" DOTFILES_ROOT="$DOTFILES_ROOT" DOTFILES_SHELL_MODE=normal \
    bash --noprofile --rcfile "$DOTFILES_ROOT/bash/.bashrc" -ic \
    'test "$DOTFILES_SHELL_EFFECTIVE_MODE" = normal; dotfiles-shell-diagnostics >/dev/null; exit'
}

zsh_runtime() {
  if ! has_cmd zsh; then
    skip "Zsh runtime: zsh not installed"
    return 0
  fi

  local tmp_home
  tmp_home=$(mktemp -d)
  HOME="$tmp_home" ZDOTDIR="$DOTFILES_ROOT/zsh" DOTFILES_SHELL_MODE=normal \
    zsh -ic 'test "$DOTFILES_SHELL_EFFECTIVE_MODE" = normal; exit'
}

tmux_runtime() {
  if ! has_cmd tmux; then
    skip "tmux runtime: tmux not installed"
    return 0
  fi

  local socket="dotfiles-test-$$"
  (
    trap 'tmux -L "$socket" kill-server >/dev/null 2>&1 || true' EXIT
    tmux -L "$socket" -f "$DOTFILES_ROOT/tmux/tmux.conf" new-session -d -s smoke -c /tmp || exit 1
    [ "$(tmux -L "$socket" show-options -gv prefix 2>/dev/null)" = C-a ] || exit 1
    tmux -L "$socket" list-keys >/dev/null || exit 1
    tmux -L "$socket" source-file "$DOTFILES_ROOT/tmux/tmux.conf" || exit 1
  )
}

nvim_runtime() {
  if ! has_cmd nvim; then
    skip "Neovim runtime: nvim not installed"
    return 0
  fi

  if ! nvim --headless --clean \
    '+if has("nvim-0.11.3") == 0 | cquit | endif' '+qa' >/dev/null 2>&1; then
    skip "Neovim runtime: version older than 0.11.3"
    return 0
  fi

  local tmp
  tmp=$(mktemp -d)
  XDG_DATA_HOME="$tmp/data" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache" \
    DOTFILES_NVIM_BOOTSTRAP=0 \
    nvim --headless -u "$DOTFILES_ROOT/nvim/.config/nvim/init.lua" '+qa'
}

wezterm_runtime() {
  if ! has_cmd wezterm; then
    skip "WezTerm runtime: wezterm not installed"
    return 0
  fi

  DOTFILES_WEZTERM_MODE=minimal \
    wezterm --config-file "$DOTFILES_ROOT/wezterm/.wezterm.lua" show-keys >/dev/null
}

git_runtime() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)
  HOME="$tmp_home" git config --file "$DOTFILES_ROOT/git/.gitconfig" --list >/dev/null || return 1
  HOME="$tmp_home" git -C "$tmp_repo" init -q || return 1
}

run_static() {
  run_check "Git whitespace" git -C "$DOTFILES_ROOT" diff --check
  run_check "Bash syntax" check_bash_syntax
  run_check "ShellCheck" check_shellcheck
  run_check "Zsh syntax" check_zsh_syntax
  run_check "Lua syntax" check_lua_syntax
  run_check "JSON manifest" check_json
  run_check "YAML lint" check_yaml
  run_check "Docker Compose config" check_compose
  run_check "No personal hard-coded paths" check_hardcoded_paths
  run_check "Critical keymap contract" check_keymap_contract
}

run_runtime() {
  run_check "Bash isolated startup" bash_runtime
  run_check "Zsh isolated startup" zsh_runtime
  run_check "tmux isolated startup/reload" tmux_runtime
  run_check "Neovim headless startup" nvim_runtime
  run_check "WezTerm config load" wezterm_runtime
  run_check "Git isolated config" git_runtime
}

case "$PROFILE" in
  static) run_static ;;
  runtime) run_runtime ;;
  full) run_static; run_runtime ;;
esac

printf '\nResult: %d failure(s), %d skipped check(s)\n' "$FAILURES" "$SKIPS"
[ "$FAILURES" -eq 0 ]
