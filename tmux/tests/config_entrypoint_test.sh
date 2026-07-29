#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
TMUX_DIR="$ROOT/tmux"
TMP=$(mktemp -d)

cleanup() {
  tmux -L "dotfiles-direct-$$" kill-server >/dev/null 2>&1 || true
  tmux -L "dotfiles-symlink-$$" kill-server >/dev/null 2>&1 || true
  tmux -L "dotfiles-copied-$$" kill-server >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_loaded() {
  local socket=$1 expected_root=$2
  local actual_root prefix

  actual_root=$(tmux -L "$socket" show-option -gqv @tmux_root)
  [ "$actual_root" = "$expected_root" ] \
    || fail "root mismatch: expected $expected_root, got ${actual_root:-<empty>}"

  prefix=$(tmux -L "$socket" show-option -gv prefix)
  [ "$prefix" = C-a ] \
    || fail "modular config was not loaded synchronously: prefix=$prefix"
}

if ! command -v tmux >/dev/null 2>&1; then
  printf 'SKIP: tmux config entrypoint (tmux not installed)\n'
  exit 0
fi

expected_root=$(cd "$TMUX_DIR" && pwd -P)

# Direct loading must resolve the canonical config directory.
direct_home="$TMP/direct-home"
mkdir -p "$direct_home"
direct_socket="dotfiles-direct-$$"
HOME="$direct_home" DOTFILES_ROOT="$ROOT" \
  tmux -L "$direct_socket" -f "$TMUX_DIR/tmux.conf" new-session -d -s test
assert_loaded "$direct_socket" "$expected_root"
tmux -L "$direct_socket" kill-server

# The bootstrap contract uses a symlink at ~/.tmux.conf.
symlink_home="$TMP/symlink-home"
mkdir -p "$symlink_home"
ln -s "$TMUX_DIR/tmux.conf" "$symlink_home/.tmux.conf"
symlink_socket="dotfiles-symlink-$$"
HOME="$symlink_home" DOTFILES_ROOT="$ROOT" \
  tmux -L "$symlink_socket" -f "$symlink_home/.tmux.conf" new-session -d -s test
assert_loaded "$symlink_socket" "$expected_root"
tmux -L "$symlink_socket" kill-server

# A copied ~/.tmux.conf must fall back to DOTFILES_ROOT instead of looking for
# modular files beside the copied entrypoint.
copied_home="$TMP/copied-home"
mkdir -p "$copied_home"
cp "$TMUX_DIR/tmux.conf" "$copied_home/.tmux.conf"
copied_socket="dotfiles-copied-$$"
HOME="$copied_home" DOTFILES_ROOT="$ROOT" \
  tmux -L "$copied_socket" -f "$copied_home/.tmux.conf" new-session -d -s test
assert_loaded "$copied_socket" "$expected_root"
tmux -L "$copied_socket" kill-server

printf 'PASS: tmux config entrypoint\n'
