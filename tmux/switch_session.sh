#!/usr/bin/env bash
# switch_session.sh <index>
# Switch tmux client to the session whose session_index matches <index>.
set -euo pipefail
idx="$1"
if [ -z "$idx" ]; then
  exit 0
fi
name=$(tmux list-sessions -F "#{session_index}:#{session_name}" 2>/dev/null | awk -F: -v i="$idx" '$1==i{print $2; exit}')
if [ -n "$name" ]; then
  tmux switch-client -t "$name" 2>/dev/null || true
fi
exit 0
