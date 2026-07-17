#!/usr/bin/env bash
set -u

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 1 "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 1 "$@"
  else
    "$@"
  fi
}

clipboard_data=""

if command -v wl-paste >/dev/null 2>&1; then
  clipboard_data="$(run_with_timeout wl-paste --no-newline 2>/dev/null || true)"
fi

if [ -z "$clipboard_data" ] && command -v xclip >/dev/null 2>&1; then
  clipboard_data="$(run_with_timeout xclip -o -selection clipboard 2>/dev/null || true)"
fi

if [ -z "$clipboard_data" ] && command -v pbpaste >/dev/null 2>&1; then
  clipboard_data="$(run_with_timeout pbpaste 2>/dev/null || true)"
fi

if [ -z "$clipboard_data" ] && command -v powershell.exe >/dev/null 2>&1; then
  clipboard_data="$(run_with_timeout powershell.exe -NoProfile -Command 'Get-Clipboard -Raw' 2>/dev/null | tr -d '\r' || true)"
fi

[ -n "$clipboard_data" ] || exit 0
printf '%s' "$clipboard_data" | tmux load-buffer - >/dev/null 2>&1 || exit 0
tmux paste-buffer >/dev/null 2>&1 || true
