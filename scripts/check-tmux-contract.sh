#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLIPBOARD="$ROOT/tmux/clipboard-paste.sh"
WORKFLOW="$ROOT/tmux/workflow.conf"
PLUGINS="$ROOT/tmux/plugins.conf"
OBSERVABILITY="$ROOT/tmux/observability.conf"
NAVIGATOR="$ROOT/nvim/.config/nvim/lua/plugins/vim-tmux-navigator.lua"
ENTRYPOINT_TEST="$ROOT/tmux/tests/config_entrypoint_test.sh"

tmp=$(mktemp -d)
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/tmux" <<'EOF'
#!/bin/bash
case "${1:-}" in
  load-buffer)
    [ "${2:-}" = - ] || exit 2
    /bin/cat > "$DOTFILES_CLIPBOARD_CAPTURE"
    ;;
  paste-buffer)
    : > "$DOTFILES_CLIPBOARD_PASTED"
    ;;
  *)
    exit 2
    ;;
esac
EOF

cat > "$tmp/bin/wl-paste" <<'EOF'
#!/bin/bash
printf 'wl\n' >> "$DOTFILES_PROVIDER_LOG"
if [ "${1:-}" = "--no-newline" ]; then
  printf 'wayland'
else
  printf 'wayland\n\n'
fi
EOF

cat > "$tmp/bin/xclip" <<'EOF'
#!/bin/bash
printf 'x11\n' >> "$DOTFILES_PROVIDER_LOG"
printf 'x11\n\n'
EOF

chmod +x "$tmp/bin/tmux" "$tmp/bin/wl-paste" "$tmp/bin/xclip"

run_case() {
  local name=$1 wayland=$2 display=$3 ssh=$4 expected_provider=$5 expected_text=$6 path=$7
  local case_dir="$tmp/$name"
  mkdir -p "$case_dir"
  : > "$case_dir/provider.log"

  env \
    HOME="$case_dir/home" \
    WAYLAND_DISPLAY="$wayland" \
    DISPLAY="$display" \
    SSH_CONNECTION="$ssh" \
    DOTFILES_PROVIDER_LOG="$case_dir/provider.log" \
    DOTFILES_CLIPBOARD_CAPTURE="$case_dir/capture" \
    DOTFILES_CLIPBOARD_PASTED="$case_dir/pasted" \
    PATH="$path" \
    /bin/bash "$CLIPBOARD"

  if [ -z "$expected_provider" ]; then
    [ ! -s "$case_dir/provider.log" ]
    [ ! -e "$case_dir/pasted" ]
    return
  fi

  printf '%s\n' "$expected_provider" > "$case_dir/expected-provider"
  cmp -s "$case_dir/expected-provider" "$case_dir/provider.log"
  printf '%b' "$expected_text" > "$case_dir/expected-text"
  cmp -s "$case_dir/expected-text" "$case_dir/capture"
  [ -e "$case_dir/pasted" ]
}

run_case wayland wayland-0 :0 "" wl 'wayland\n\n' "$tmp/bin:/usr/bin:/bin"
run_case x11 "" :0 "" x11 'x11\n\n' "$tmp/bin:/usr/bin:/bin"
run_case ssh wayland-0 :0 "client 1 2" "" "" "$tmp/bin:/usr/bin:/bin"
run_case no-timeout wayland-0 "" "" wl 'wayland\n\n' "$tmp/bin"

grep -Eq '^bind[[:space:]]+p[[:space:]]+run-shell' "$WORKFLOW"
if grep -Eq '^bind(-key)?[[:space:]]+-n[[:space:]]+S-Insert' "$WORKFLOW"; then
  printf 'tmux must leave Shift+Insert to the terminal/application\n' >&2
  exit 1
fi

grep -Fq 'set -g @vim_navigator_prefix_mapping_clear_screen ""' "$PLUGINS"
grep -Fq 'christoomey/vim-tmux-navigator' "$NAVIGATOR"
grep -Fq 'lazy = false' "$NAVIGATOR"

if grep -Rq '@tmux_nested_level' "$OBSERVABILITY" "$ROOT/tmux"/*.sh; then
  printf 'tmux must not infer a fake numeric nesting depth\n' >&2
  exit 1
fi

bash "$ENTRYPOINT_TEST"

printf 'check-tmux-contract: PASS\n'
