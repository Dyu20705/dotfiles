#!/usr/bin/env bash
# update_cached_status.sh — read ~/.cache/tmux_status and write to tmux option @tmux_cached_status
set -euo pipefail
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux_status"
if [ -r "$CACHE_FILE" ]; then
  val=$(cat "$CACHE_FILE" 2>/dev/null || true)
  # Trim trailing newlines
  val=$(printf "%s" "$val" | tr -d '\n')
  [ -n "$val" ] && tmux set-option -gq @tmux_cached_status "$val" 2>/dev/null || tmux set-option -gq @tmux_cached_status "" 2>/dev/null
fi
exit 0
