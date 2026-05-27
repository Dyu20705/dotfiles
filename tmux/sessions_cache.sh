#!/usr/bin/env bash
# sessions_cache.sh — build a compact session list suitable for tmux status-left
# Output example: [1:dev] [2:notes] [3:server] with the active session highlighted

set -euo pipefail

OUTFILE="$XDG_CACHE_HOME"/tmux_sessions
TMP=$(mktemp)
CURRENT=$(tmux display-message -p '#S' 2>/dev/null || true)

format_session() {
  idx="$1"
  name="$2"
  if [ "$name" = "$CURRENT" ]; then
    # highlighted active session
    printf "#[reverse] [%s:%s] #[default] " "$idx" "$name"
  else
    printf "[%s:%s] " "$idx" "$name"
  fi
}

# Build list
{
  while IFS= read -r line; do
    idx=$(echo "$line" | awk -F: '{print $1}')
    name=$(echo "$line" | awk -F: '{print $2}')
    format_session "$idx" "$name"
  done < <(tmux list-sessions -F "#{session_index}:#{session_name}" 2>/dev/null | sort -n)
  echo
} > "$TMP"

mkdir -p "$(dirname "$OUTFILE")"
mv "$TMP" "$OUTFILE"
chmod 644 "$OUTFILE"

# Also push into tmux option for immediate availability
VAL=$(cat "$OUTFILE" 2>/dev/null || true)
[ -n "$VAL" ] && tmux set-option -gq @tmux_sessions "$VAL" 2>/dev/null || true

exit 0
