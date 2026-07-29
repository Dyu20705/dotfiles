#!/usr/bin/env bash
set -euo pipefail
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"
bytes=$(wc -c < "$TMP" | tr -d ' ')
max=${DOTFILES_OSC52_MAX_BYTES:-100000}

if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$TMP"
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$TMP"
elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
  xsel --clipboard --input < "$TMP"
elif [ "$(uname -s 2>/dev/null || true)" = Darwin ] && command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$TMP"
else
  [ "$bytes" -le "$max" ] || {
    printf 'clipboard payload exceeds OSC52 limit (%s > %s)\n' "$bytes" "$max" >&2
    exit 10
  }
  encoded=$(base64 < "$TMP" | tr -d '\r\n')
  if [ -w /dev/tty ]; then
    printf '\033]52;c;%s\a' "$encoded" > /dev/tty
  else
    printf '\033]52;c;%s\a' "$encoded"
  fi
fi
