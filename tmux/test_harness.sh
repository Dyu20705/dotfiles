#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/tmux.conf"
SOCKET="${TMUX_TEST_SOCKET:-dotfiles-test-$$}"
SESSION="${TMUX_TEST_SESSION:-smoke}"

command -v tmux >/dev/null 2>&1 || {
  printf 'tmux is required\n' >&2
  exit 1
}

cleanup() {
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
}
trap cleanup EXIT

assert_equal() {
  local expected=$1 actual=$2 label=$3
  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s (expected %s, got %s)\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$label"
}

tmux -L "$SOCKET" -f "$CONFIG" new-session -d -s "$SESSION" -c /tmp
assert_equal C-a "$(tmux -L "$SOCKET" show-options -gv prefix)" 'prefix is C-a'
assert_equal "$SCRIPT_DIR" "$(tmux -L "$SOCKET" show-options -gqv @tmux_root)" 'tmux root resolves from config'

tmux -L "$SOCKET" list-keys >/dev/null
printf 'PASS: key table loads\n'

tmux -L "$SOCKET" source-file "$CONFIG"
assert_equal C-a "$(tmux -L "$SOCKET" show-options -gv prefix)" 'reload preserves prefix'

if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg socket "$SOCKET" \
    --arg session "$SESSION" \
    --arg root "$SCRIPT_DIR" \
    '{status:"ok",socket:$socket,session:$session,root:$root}'
else
  printf 'tmux smoke test complete\n'
fi
