#!/usr/bin/env bash
set -euo pipefail

CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="${TMUX_CACHE_DIR:-$CACHE_HOME/dotfiles/tmux}"
OUTFILE="${TMUX_SESSIONS_CACHE:-$CACHE_DIR/sessions.txt}"
TMP=$(mktemp "${TMPDIR:-/tmp}/dotfiles-tmux-sessions.XXXXXX")
trap 'rm -f "$TMP"' EXIT

CURRENT=$(tmux display-message -p '#S' 2>/dev/null || true)
mkdir -p "$CACHE_DIR"

format_session() {
  local idx=$1
  local name=$2
  if [ "$name" = "$CURRENT" ]; then
    printf '#[reverse] [%s:%s] #[default] ' "$idx" "$name"
  else
    printf '[%s:%s] ' "$idx" "$name"
  fi
}

{
  while IFS=$'\t' read -r idx name; do
    [ -n "$idx" ] || continue
    format_session "$idx" "$name"
  done < <(tmux list-sessions -F $'#{session_index}\t#{session_name}' 2>/dev/null | sort -n -k1,1)
  printf '\n'
} > "$TMP"

mv "$TMP" "$OUTFILE"
chmod 600 "$OUTFILE"
trap - EXIT

VALUE=$(tr -d '\n' < "$OUTFILE" 2>/dev/null || true)
tmux set-option -gq @tmux_sessions "$VALUE" 2>/dev/null || true
