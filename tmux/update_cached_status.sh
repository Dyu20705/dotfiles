#!/usr/bin/env bash
# update_cached_status.sh — read ~/.cache/tmux_status and write to tmux option @tmux_cached_status
set -euo pipefail
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux_status"
if [ -r "$CACHE_FILE" ]; then
  val=$(cat "$CACHE_FILE" 2>/dev/null || true)
  # Trim trailing newlines
  val=$(printf "%s" "$val" | tr -d '\n')
  # Sanitize hashes to avoid tmux format injection (escape #)
  safe=$(printf "%s" "$val" | sed 's/#/##/g')
  if [ -n "$safe" ]; then
    tmux set-option -gq @tmux_cached_status "$safe" 2>/dev/null || tmux set-option -gq @tmux_cached_status "" 2>/dev/null
    # Force clients to refresh less often by using larger status-interval and refresh on update
    tmux refresh-client -S 2>/dev/null || true
  else
    tmux set-option -gq @tmux_cached_status "" 2>/dev/null || true
  fi
fi
exit 0
