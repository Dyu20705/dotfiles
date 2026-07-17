#!/usr/bin/env bash
set -euo pipefail

CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="${TMUX_STATUS_CACHE:-$CACHE_HOME/dotfiles/tmux/status.txt}"

if [ ! -r "$CACHE_FILE" ]; then
  tmux set-option -gq @tmux_cached_status "" 2>/dev/null || true
  exit 0
fi

value=$(tr -d '\n' < "$CACHE_FILE" 2>/dev/null || true)
safe=$(printf '%s' "$value" | sed 's/#/##/g')
tmux set-option -gq @tmux_cached_status "$safe" 2>/dev/null || true
tmux refresh-client -S 2>/dev/null || true
