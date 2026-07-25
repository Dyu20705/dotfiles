#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TMUX_DIR="$ROOT/tmux"
TMP=$(mktemp -d)
REALPATH=$(command -v realpath)

cleanup() {
  tmux -L dotfiles-direct-$$ kill-server 2>/dev/null || true
  tmux -L dotfiles-copied-$$ kill-server 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$TMP/bin"
cat > "$TMP/bin/realpath" <<EOF_REALPATH
#!/usr/bin/env bash
sleep 1
exec "$REALPATH" "\$@"
EOF_REALPATH
chmod +x "$TMP/bin/realpath"

assert_loaded() {
  local socket=$1
  local expected_root=$2
  local actual_root prefix

  actual_root=$(tmux -L "$socket" show-option -gqv @tmux_root)
  [ "$actual_root" = "$expected_root" ] || fail "root mismatch: expected $expected_root, got ${actual_root:-<empty>}"

  prefix=$(tmux -L "$socket" show-option -gv prefix)
  [ "$prefix" = "C-a" ] || fail "modular config was not loaded synchronously: prefix=$prefix"
}

# Loading the canonical file directly must resolve the file currently being parsed,
# not whichever default config originally started the server.
direct_home="$TMP/direct-home"
mkdir -p "$direct_home/dotfiles"
ln -s "$TMUX_DIR" "$direct_home/dotfiles/tmux"
direct_socket="dotfiles-direct-$$"
HOME="$direct_home" PATH="$TMP/bin:$PATH" \
  tmux -L "$direct_socket" -f "$TMUX_DIR/tmux.conf" new-session -d -s test
assert_loaded "$direct_socket" "$TMUX_DIR"
tmux -L "$direct_socket" kill-server

# A copied ~/.tmux.conf must fall back to the documented ~/dotfiles checkout.
copied_home="$TMP/copied-home"
mkdir -p "$copied_home/dotfiles"
ln -s "$TMUX_DIR" "$copied_home/dotfiles/tmux"
cp "$TMUX_DIR/tmux.conf" "$copied_home/.tmux.conf"
copied_socket="dotfiles-copied-$$"
HOME="$copied_home" PATH="$TMP/bin:$PATH" \
  tmux -L "$copied_socket" -f "$copied_home/.tmux.conf" new-session -d -s test
assert_loaded "$copied_socket" "$TMUX_DIR"
tmux -L "$copied_socket" kill-server

printf 'PASS: tmux config entrypoint\n'
