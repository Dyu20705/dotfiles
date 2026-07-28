#!/usr/bin/env bash

# shellcheck source=scripts/lib/common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

dotfiles_detect_context() {
  if [ -n "${DOTFILES_CONTEXT:-}" ]; then
    validate_context "$DOTFILES_CONTEXT"
    printf '%s\n' "$DOTFILES_CONTEXT"
    return
  fi
  if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ] || [ -n "${CI:-}" ]; then
    printf 'remote\n'
  elif [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    printf 'desktop\n'
  else
    printf 'server\n'
  fi
}

dotfiles_effective_profile() {
  local requested=${DOTFILES_PROFILE:-${DOTFILES_SHELL_MODE:-normal}}
  local context=$1
  validate_profile "$requested"
  case "$context:$requested:${DOTFILES_ALLOW_FULL_REMOTE:-0}" in
    remote:minimal:*|server:minimal:*) printf 'minimal\n' ;;
    remote:*:1|server:*:1) printf '%s\n' "$requested" ;;
    remote:*:*|server:*:*) printf 'minimal\n' ;;
    *) printf '%s\n' "$requested" ;;
  esac
}

dotfiles_capability_file() { printf '%s/dotfiles/capabilities\n' "$(xdg_config_home)"; }
dotfiles_selected_capabilities() {
  local file
  file=$(dotfiles_capability_file)
  [ -r "$file" ] || return 0
  awk 'NF && $1 !~ /^#/ { print $1 }' "$file" | sort -u
}
dotfiles_active_capabilities() {
  local profile=$1
  [ "$profile" != minimal ] || return 0
  dotfiles_selected_capabilities
}
dotfiles_capability_known() {
  local id=$1
  jq -e --arg id "$id" '.capability_packs | index($id) != null' "$DOTFILES_MANIFEST" >/dev/null
}
