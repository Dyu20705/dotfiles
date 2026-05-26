#!/usr/bin/env bash

set +e

clipboard_data=""

if command -v wl-paste >/dev/null 2>&1; then
  clipboard_data="$(timeout 1 wl-paste 2>/dev/null || true)"
fi

if [ -z "$clipboard_data" ] && command -v xclip >/dev/null 2>&1; then
  clipboard_data="$(timeout 1 xclip -o -selection clipboard 2>/dev/null || true)"
fi

if [ -z "$clipboard_data" ] && command -v pbpaste >/dev/null 2>&1; then
  clipboard_data="$(timeout 1 pbpaste 2>/dev/null || true)"
fi

[ -n "$clipboard_data" ] || exit 0

printf '%s' "$clipboard_data" | tmux load-buffer - >/dev/null 2>&1 || exit 0
tmux paste-buffer >/dev/null 2>&1 || true
