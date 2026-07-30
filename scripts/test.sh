#!/usr/bin/env bash
# The single-quoted command snippets below are intentionally expanded by the
# child Zsh process, not by this test harness.
# shellcheck disable=SC2016
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

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

skip() {
  printf '[SKIP] %s\n' "$1"
  SKIPS=$((SKIPS + 1))
}

run_check() {
  local name=$1
  shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

shell_scripts() {
  find \
    "$DOTFILES_ROOT/git" \
    "$DOTFILES_ROOT/tmux" \
    "$DOTFILES_ROOT/scripts" \
    "$DOTFILES_ROOT/capabilities" \
    -type f -name '*.sh' -print0
}

check_bash_syntax() {
  local files=()
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <(shell_scripts)
  bash -n "${files[@]}"
}

check_shellcheck() {
  if ! has_cmd shellcheck; then
    skip "ShellCheck not installed"
    return 0
  fi

  local scripts=()
  while IFS= read -r -d '' file; do
    scripts+=("$file")
  done < <(shell_scripts)

  shellcheck -x "${scripts[@]}"
}

check_zsh_syntax() {
  if ! has_cmd zsh; then
    skip "Zsh not installed"
    return 0
  fi

  zsh -n \
    "$DOTFILES_ROOT/zsh/.zshrc" \
    "$DOTFILES_ROOT/zsh/common.zsh"
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
  done < <(
    find "$DOTFILES_ROOT/nvim" "$DOTFILES_ROOT/wezterm" \
      -type f -name '*.lua' -print0
  )
}

check_json() {
  validate_manifest
}

check_manifest_rejects_unsafe_target() {
  local tmp_home tmp_manifest outside result
  tmp_home=$(mktemp -d)
  tmp_manifest=$(mktemp)
  outside="${TMPDIR:-/tmp}/dotfiles-unsafe-target-$$"

  jq --arg target "$outside" '.links[0].target = $target' \
    "$DOTFILES_ROOT/config/workflow.json" > "$tmp_manifest" || {
      rm -rf "$tmp_home" "$tmp_manifest"
      return 1
    }

  if HOME="$tmp_home" DOTFILES_MANIFEST="$tmp_manifest" \
    bash "$DOTFILES_ROOT/scripts/bootstrap.sh" --profile normal --dry-run \
    >/dev/null 2>&1; then
    rm -rf "$tmp_home" "$tmp_manifest" "$outside"
    return 1
  fi

  [ ! -e "$outside" ] && [ ! -L "$outside" ]
  result=$?
  rm -rf "$tmp_home" "$tmp_manifest" "$outside"
  return "$result"
}

check_doctor_json() {
  local app_count output tmp_home
  tmp_home=$(mktemp -d)
  app_count=$(jq '.apps | length' "$DOTFILES_ROOT/config/workflow.json")
  output=$(
    HOME="$tmp_home" \
      XDG_CONFIG_HOME="$tmp_home/.config" \
      XDG_CACHE_HOME="$tmp_home/.cache" \
      XDG_STATE_HOME="$tmp_home/.local/state" \
      XDG_DATA_HOME="$tmp_home/.local/share" \
      bash "$DOTFILES_ROOT/scripts/doctor.sh" --profile minimal --json \
      2>/dev/null || true
  )
  rm -rf "$tmp_home"

  printf '%s\n' "$output" | jq -e --argjson app_count "$app_count" '
    .schema_version == 1
    and .profile == "minimal"
    and ([.checks[] | select(.type == "command")] | length == $app_count)
    and (.summary.failures | type == "number")
  ' >/dev/null
}

check_doctor_deployment_contract() {
  local tmp_home tmp_bin output target result
  tmp_home=$(mktemp -d)
  tmp_bin=$(mktemp -d)
  target="$tmp_home/.gitconfig"

  HOME="$tmp_home" \
    XDG_CONFIG_HOME="$tmp_home/.config" \
    XDG_CACHE_HOME="$tmp_home/.cache" \
    XDG_STATE_HOME="$tmp_home/.local/state" \
    XDG_DATA_HOME="$tmp_home/.local/share" \
    bash "$DOTFILES_ROOT/scripts/bootstrap.sh" --profile minimal >/dev/null || {
      rm -rf "$tmp_home" "$tmp_bin"
      return 1
    }

  rm -f "$target"
  printf '[user]\n' > "$target"

  cat > "$tmp_bin/git" <<'EOF'
#!/usr/bin/env bash
printf 'git version unknown\n'
EOF
  chmod +x "$tmp_bin/git"

  output=$(
    PATH="$tmp_bin:$PATH" \
      HOME="$tmp_home" \
      XDG_CONFIG_HOME="$tmp_home/.config" \
      XDG_CACHE_HOME="$tmp_home/.cache" \
      XDG_STATE_HOME="$tmp_home/.local/state" \
      XDG_DATA_HOME="$tmp_home/.local/share" \
      bash "$DOTFILES_ROOT/scripts/doctor.sh" --profile minimal --json \
      2>/dev/null || true
  )

  printf '%s\n' "$output" | jq -e --arg target "$target" '
    any(.checks[];
      .type == "link" and .target == $target and .status == "not-symlink"
    )
    and any(.checks[];
      .type == "command" and .command == "git" and .status == "version-unknown"
    )
    and .summary.failures >= 2
  ' >/dev/null
  result=$?
  rm -rf "$tmp_home" "$tmp_bin"
  return "$result"
}

check_bootstrap_dry_run() {
  local tmp_home
  tmp_home=$(mktemp -d)

  HOME="$tmp_home" \
    XDG_CONFIG_HOME="$tmp_home/.config" \
    XDG_CACHE_HOME="$tmp_home/.cache" \
    XDG_STATE_HOME="$tmp_home/.local/state" \
    XDG_DATA_HOME="$tmp_home/.local/share" \
    bash "$DOTFILES_ROOT/scripts/bootstrap.sh" --profile normal --dry-run \
    >/dev/null || {
      rm -rf "$tmp_home"
      return 1
    }

  if find "$tmp_home" -mindepth 1 -print -quit | grep -q .; then
    rm -rf "$tmp_home"
    return 1
  fi
  rm -rf "$tmp_home"
}

checkout_shell_snapshot() {
  find "$DOTFILES_ROOT/scripts" "$DOTFILES_ROOT/tmux" "$DOTFILES_ROOT/git" \
    "$DOTFILES_ROOT/capabilities" \
    -type f -name '*.sh' -print \
    | sort \
    | while IFS= read -r file; do
        if [ -x "$file" ]; then
          executable=x
        else
          executable=-
        fi
        checksum=$(cksum "$file")
        printf '%s\t%s\t%s\n' "$file" "$executable" "$checksum"
      done \
    | cksum
}

check_bootstrap_preserves_checkout() {
  local after before tmp_home
  tmp_home=$(mktemp -d)
  before=$(checkout_shell_snapshot)

  HOME="$tmp_home" \
    XDG_CONFIG_HOME="$tmp_home/.config" \
    XDG_CACHE_HOME="$tmp_home/.cache" \
    XDG_STATE_HOME="$tmp_home/.local/state" \
    XDG_DATA_HOME="$tmp_home/.local/share" \
    bash "$DOTFILES_ROOT/scripts/bootstrap.sh" --profile normal \
    >/dev/null || {
      rm -rf "$tmp_home"
      return 1
    }

  after=$(checkout_shell_snapshot)
  rm -rf "$tmp_home"
  [ "$before" = "$after" ]
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
  # The expression intentionally matches the literal text `$HOME`.
  matches=$(
    git -C "$DOTFILES_ROOT" grep -nE \
      '(\$HOME/dotfiles|~/dotfiles|/home/[^/]+/|/Users/[^/]+/|Documents/git)' -- \
      ':!README.md' \
      ':!docs/**' \
      ':!scripts/test.sh' \
      ':!scripts/security-check.sh' \
      ':!scripts/tests/**' 2>/dev/null || true
  )
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" >&2
    return 1
  fi
}

check_keymap_contract() {
  local nvim_navigator_count test_file_count tmux_navigator_count

  test_file_count=$(
    grep -RhoE "['\"]<leader>tf['\"]" \
      "$DOTFILES_ROOT/nvim/.config/nvim/lua" 2>/dev/null \
      | wc -l \
      | tr -d ' '
  )
  if [ "$test_file_count" -gt 1 ]; then
    printf '<leader>tf is declared %s times\n' "$test_file_count" >&2
    return 1
  fi

  if grep -RqsE '^bind(-key)?[[:space:]]+-n[[:space:]]+C-v' \
    "$DOTFILES_ROOT/tmux"; then
    printf 'tmux must not steal Ctrl+V from applications\n' >&2
    return 1
  fi

  nvim_navigator_count=$(
    grep -Rhl 'christoomey/vim-tmux-navigator' \
      "$DOTFILES_ROOT/nvim/.config/nvim/lua/plugins" 2>/dev/null \
      | wc -l \
      | tr -d ' '
  )
  tmux_navigator_count=$(
    grep -Fhc "set -g @plugin 'christoomey/vim-tmux-navigator'" \
      "$DOTFILES_ROOT/tmux/plugins.conf" 2>/dev/null || true
  )

  if [ "$nvim_navigator_count" -ne 1 ] \
    || [ "$tmux_navigator_count" -ne 1 ]; then
    printf 'vim-tmux-navigator must be declared once in both Neovim and tmux\n' >&2
    return 1
  fi

  jq -e '."vim-tmux-navigator".commit | test("^[0-9a-f]{40}$")' \
    "$DOTFILES_ROOT/nvim/.config/nvim/lazy-lock.json" >/dev/null
}

check_git_tool_contract() {
  local config="$DOTFILES_ROOT/git/.gitconfig"
  [ "$(git config --file "$config" --get merge.tool)" = nvimdiff ] || return 1
  [ "$(git config --file "$config" --get diff.tool)" = nvimdiff ] || return 1
  [ "$(git config --file "$config" --get mergetool.nvimdiff.layout)" \
    = LOCAL,MERGED,REMOTE ] || return 1
  [ "$(git config --file "$config" --get mergetool.keepBackup)" = false ] \
    || return 1
  ! git config --file "$config" --get mergetool.nvimdiff.cmd \
    >/dev/null 2>&1 || return 1
  ! git config --file "$config" --get mergetool.nvimdiff.trustExitCode \
    >/dev/null 2>&1
}

check_clipboard_pipeline() {
  local tmp capture expected marker result
  tmp=$(mktemp -d)
  capture="$tmp/capture"
  expected="$tmp/expected"
  marker="$tmp/pasted"
  mkdir -p "$tmp/bin"

  cat > "$tmp/bin/wl-paste" <<'EOF'
#!/usr/bin/env bash
printf 'first line\nsecond line\n'
EOF

  cat > "$tmp/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  load-buffer)
    [ "${2:-}" = - ] || exit 2
    cat > "$DOTFILES_CLIPBOARD_CAPTURE"
    ;;
  paste-buffer)
    : > "$DOTFILES_CLIPBOARD_PASTED"
    ;;
  *)
    exit 2
    ;;
esac
EOF

  chmod +x "$tmp/bin/wl-paste" "$tmp/bin/tmux"
  printf 'first line\nsecond line\n' > "$expected"

  PATH="$tmp/bin:/usr/bin:/bin" \
    DOTFILES_CLIPBOARD_CAPTURE="$capture" \
    DOTFILES_CLIPBOARD_PASTED="$marker" \
    bash "$DOTFILES_ROOT/tmux/clipboard-paste.sh" || {
      rm -rf "$tmp"
      return 1
    }

  cmp -s "$expected" "$capture" && [ -f "$marker" ]
  result=$?
  rm -rf "$tmp"
  return "$result"
}

zsh_runtime() {
  if ! has_cmd zsh; then
    skip "Zsh runtime: zsh not installed"
    return 0
  fi

  local tmp_home root result
  tmp_home=$(mktemp -d)
  root=$DOTFILES_ROOT

  env CI='' SSH_CONNECTION='' SSH_TTY='' TMUX='' \
    HOME="$tmp_home" ZDOTDIR="$root/zsh" DOTFILES_SHELL_MODE=normal \
    DOTFILES_SKIP_COMPLETION=1 \
    zsh -d -ic \
    'test "$DOTFILES_SHELL_EFFECTIVE_MODE" = normal; test "$DOTFILES_SHELL_IN_TMUX" = 0; exit' \
    || {
      rm -rf "$tmp_home"
      return 1
    }

  env CI='' SSH_CONNECTION='' SSH_TTY='' TMUX=/tmp/dotfiles-test,1,0 \
    HOME="$tmp_home" ZDOTDIR="$root/zsh" DOTFILES_SHELL_MODE=normal \
    DOTFILES_SKIP_COMPLETION=1 \
    zsh -d -ic \
    'test "$DOTFILES_SHELL_EFFECTIVE_MODE" = normal; test "$DOTFILES_SHELL_IN_TMUX" = 1; exit' \
    || {
      rm -rf "$tmp_home"
      return 1
    }

  env CI=true SSH_CONNECTION='' SSH_TTY='' TMUX='' \
    HOME="$tmp_home" ZDOTDIR="$root/zsh" DOTFILES_SHELL_MODE=normal \
    DOTFILES_SKIP_COMPLETION=1 \
    zsh -d -ic \
    'test "$DOTFILES_SHELL_EFFECTIVE_MODE" = minimal; test "$DOTFILES_SHELL_REMOTE" = 1; exit' \
    || {
      rm -rf "$tmp_home"
      return 1
    }

  env CI='' SSH_CONNECTION='' SSH_TTY='' TMUX='' \
    HOME="$tmp_home" ZDOTDIR="$root/zsh" DOTFILES_SHELL_MODE=invalid \
    DOTFILES_SKIP_COMPLETION=1 \
    zsh -d -ic \
    'test "$DOTFILES_SHELL_MODE" = normal; test "$DOTFILES_SHELL_EFFECTIVE_MODE" = normal; exit'
  result=$?
  rm -rf "$tmp_home"
  return "$result"
}

tmux_runtime() {
  if ! has_cmd tmux; then
    skip "tmux runtime: tmux not installed"
    return 0
  fi

  local socket="dotfiles-test-$$" tmp_home
  tmp_home=$(mktemp -d)
  printf 'set -g status-left "local-overlay"\n' > "$tmp_home/.tmux.conf.local"

  (
    trap \
      'tmux -L "$socket" kill-server >/dev/null 2>&1 || true; rm -rf "$tmp_home"' \
      EXIT
    HOME="$tmp_home" tmux -L "$socket" \
      -f "$DOTFILES_ROOT/tmux/tmux.conf" \
      new-session -d -s smoke -c /tmp || exit 1
    [ "$(tmux -L "$socket" show-options -gv prefix 2>/dev/null)" = C-a ] \
      || exit 1
    [ "$(tmux -L "$socket" show-options -gqv @tmux_root 2>/dev/null)" \
      = "$DOTFILES_ROOT/tmux" ] || exit 1
    [ "$(tmux -L "$socket" show-options -gv status-left 2>/dev/null)" \
      = local-overlay ] || exit 1
    tmux -L "$socket" list-keys >/dev/null || exit 1
    tmux -L "$socket" source-file "$DOTFILES_ROOT/tmux/tmux.conf" || exit 1
    [ "$(tmux -L "$socket" show-options -gv status-left 2>/dev/null)" \
      = local-overlay ] || exit 1
  )
}

nvim_runtime() {
  if ! has_cmd nvim; then
    skip "Neovim runtime: nvim not installed"
    return 0
  fi

  if ! nvim --headless --clean \
    '+if has("nvim-0.11.3") == 0 | cquit | endif' '+qa' \
    >/dev/null 2>&1; then
    skip "Neovim runtime: version older than 0.11.3"
    return 0
  fi

  local tmp result
  tmp=$(mktemp -d)
  XDG_DATA_HOME="$tmp/data" \
    XDG_STATE_HOME="$tmp/state" \
    XDG_CACHE_HOME="$tmp/cache" \
    DOTFILES_NVIM_BOOTSTRAP=0 \
    nvim --headless -u "$DOTFILES_ROOT/nvim/.config/nvim/init.lua" \
    '+lua assert(vim.g.dotfiles_core_ready == true, "dotfiles core did not load"); assert(vim.g.dotfiles_init_error == nil, vim.g.dotfiles_init_error)' \
    '+qa'
  result=$?
  rm -rf "$tmp"
  return "$result"
}

wezterm_runtime() {
  if ! has_cmd wezterm; then
    skip "WezTerm runtime: wezterm not installed"
    return 0
  fi

  DOTFILES_WEZTERM_MODE=minimal \
    wezterm --config-file "$DOTFILES_ROOT/wezterm/.wezterm.lua" \
    show-keys >/dev/null
}

git_runtime() {
  local tmp_home tmp_repo
  tmp_home=$(mktemp -d)
  tmp_repo=$(mktemp -d)

  HOME="$tmp_home" \
    git config --file "$DOTFILES_ROOT/git/.gitconfig" --list >/dev/null || {
      rm -rf "$tmp_home" "$tmp_repo"
      return 1
    }

  HOME="$tmp_home" git -C "$tmp_repo" init -q || {
    rm -rf "$tmp_home" "$tmp_repo"
    return 1
  }

  rm -rf "$tmp_home" "$tmp_repo"
}

run_static() {
  run_check "Git whitespace" git -C "$DOTFILES_ROOT" diff --check
  run_check "Bash script syntax" check_bash_syntax
  run_check "ShellCheck" check_shellcheck
  run_check "Zsh syntax" check_zsh_syntax
  run_check "Lua syntax" check_lua_syntax
  run_check "JSON manifest contract" check_json
  run_check "Manifest rejects unsafe targets" check_manifest_rejects_unsafe_target
  run_check "Doctor JSON report" check_doctor_json
  run_check "Doctor deployment failures" check_doctor_deployment_contract
  run_check "Bootstrap dry-run is read-only" check_bootstrap_dry_run
  run_check "Bootstrap preserves checkout" check_bootstrap_preserves_checkout
  run_check "YAML lint" check_yaml
  run_check "Docker Compose config" check_compose
  run_check "No personal hard-coded paths" check_hardcoded_paths
  run_check "Critical keymap contract" check_keymap_contract
  run_check "WezTerm background and media contract" \
    bash "$DOTFILES_ROOT/scripts/check-wezterm.sh"
  run_check "Git merge tool contract" check_git_tool_contract
  run_check "Clipboard streaming contract" check_clipboard_pipeline
  run_check "Repository security baseline" \
    bash "$DOTFILES_ROOT/scripts/security-check.sh"
}

run_runtime() {
  run_check "Zsh isolated startup and mode detection" zsh_runtime
  run_check "tmux isolated startup/reload and local overlay" tmux_runtime
  run_check "Neovim headless core startup" nvim_runtime
  run_check "WezTerm config load" wezterm_runtime
  run_check "Git isolated config" git_runtime
}

case "$PROFILE" in
  static) run_static ;;
  runtime) run_runtime ;;
  full)
    run_static
    run_runtime
    ;;
esac

printf '\nResult: %d failure(s), %d skipped check(s)\n' "$FAILURES" "$SKIPS"
[ "$FAILURES" -eq 0 ]
