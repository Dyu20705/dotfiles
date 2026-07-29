#!/usr/bin/env bash
set -uo pipefail

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 1 "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 1 "$@"
  else
    "$@"
  fi
}

# A remote host does not own the desktop clipboard. Leave paste handling to the
# local terminal (for example Shift+Insert) rather than probing remote GUI tools.
if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; then
  exit 0
fi

provider=""
if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
  provider=wayland
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
  provider=x11
elif [ "$(uname -s 2>/dev/null || true)" = Darwin ] \
  && command -v pbpaste >/dev/null 2>&1; then
  provider=macos
elif [ -n "${WSL_DISTRO_NAME:-}" ] \
  && command -v powershell.exe >/dev/null 2>&1; then
  provider=wsl
else
  exit 0
fi

read_clipboard() {
  case "$provider" in
    wayland)
      run_with_timeout wl-paste 2>/dev/null
      ;;
    x11)
      run_with_timeout xclip -o -selection clipboard 2>/dev/null
      ;;
    macos)
      run_with_timeout pbpaste 2>/dev/null
      ;;
    wsl)
      run_with_timeout powershell.exe -NoProfile -Command 'Get-Clipboard -Raw' 2>/dev/null \
        | tr -d '\r'
      ;;
  esac
}

# Stream directly into tmux so multiline content and trailing data are not
# truncated by command substitution or stored in a shell variable.
if read_clipboard | tmux load-buffer - >/dev/null 2>&1; then
  tmux paste-buffer >/dev/null 2>&1 || true
fi
