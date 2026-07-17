#!/usr/bin/env bash

# Shared helpers for bootstrap, diagnostics and tests.
# This file is intentionally Bash-specific; entrypoints declare Bash explicitly.

set -o pipefail

DOTFILES_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$DOTFILES_SCRIPT_DIR/../.." && pwd)}"
DOTFILES_MANIFEST="${DOTFILES_MANIFEST:-$DOTFILES_ROOT/config/workflow.json}"

export DOTFILES_ROOT

info() {
  printf '[dotfiles] %s\n' "$*"
}

warn() {
  printf '[dotfiles] warning: %s\n' "$*" >&2
}

die() {
  printf '[dotfiles] error: %s\n' "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  has_cmd "$1" || die "required command not found: $1"
}

xdg_cache_home() {
  printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}"
}

xdg_state_home() {
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

expand_home() {
  local value=$1
  local tilde tilde_slash
  tilde=$(printf '\176')
  tilde_slash="${tilde}/"

  if [ "$value" = "$tilde" ]; then
    printf '%s\n' "$HOME"
  elif [ "${value:0:2}" = "$tilde_slash" ]; then
    printf '%s/%s\n' "$HOME" "${value:2}"
  else
    printf '%s\n' "$value"
  fi
}

portable_timeout() {
  local duration=$1
  shift

  if has_cmd timeout; then
    timeout "$duration" "$@"
  elif has_cmd gtimeout; then
    gtimeout "$duration" "$@"
  else
    "$@"
  fi
}

validate_manifest() {
  require_cmd jq
  [ -r "$DOTFILES_MANIFEST" ] || {
    warn "manifest not found: $DOTFILES_MANIFEST"
    return 1
  }

  jq -e '
    . as $root
    | ($root.schema_version == 1)
      and ($root.root_env | type == "string" and length > 0)
      and ($root.profiles | type == "object" and length > 0)
      and all($root.profiles[];
        type == "object"
        and (.description | type == "string" and length > 0)
      )
      and ($root.apps | type == "array" and length > 0)
      and all($root.apps[];
        (.name | type == "string" and length > 0)
        and (.command | type == "string" and length > 0)
        and (
          .minimum == null
          or (.minimum | type == "string" and test("^[0-9]+([.][0-9]+){1,3}$"))
        )
        and (.required_in | type == "array")
        and all(.required_in[]; . as $profile | $root.profiles[$profile] != null)
      )
      and (($root.apps | map(.name) | unique | length) == ($root.apps | length))
      and (($root.apps | map(.command) | unique | length) == ($root.apps | length))
      and ($root.links | type == "array" and length > 0)
      and all($root.links[];
        (.source
          | type == "string"
          and length > 0
          and (startswith("/") | not)
          and (test("(^|/)\\.\\.(/|$)") | not)
        )
        and (.target
          | type == "string"
          and startswith("~/")
          and length > 2
          and (test("(^|/)\\.\\.(/|$)") | not)
        )
        and (.profiles | type == "array" and length > 0)
        and all(.profiles[]; . as $profile | $root.profiles[$profile] != null)
      )
      and (($root.links | map(.target) | unique | length) == ($root.links | length))
  ' "$DOTFILES_MANIFEST" >/dev/null
}

backup_path() {
  local target=$1
  local state_home backup_root relative destination timestamp

  [ -e "$target" ] || [ -L "$target" ] || return 0

  state_home=$(xdg_state_home)
  timestamp=$(date +%Y%m%d-%H%M%S)
  relative=${target#"$HOME"/}
  backup_root=${DOTFILES_BACKUP_ROOT:-"$state_home/dotfiles/backups/$timestamp-$$"}
  destination="$backup_root/$relative"

  if [ -e "$destination" ] || [ -L "$destination" ]; then
    destination="$destination.backup-$timestamp-$$"
  fi

  mkdir -p "$(dirname "$destination")"
  mv "$target" "$destination"
  info "backed up $target -> $destination"
}

link_path() {
  local source=$1
  local target=$2
  local dry_run=${3:-0}
  local current

  case "$target" in
    "$HOME"/*) ;;
    *)
      warn "refusing to manage a target outside HOME: $target"
      return 1
      ;;
  esac

  if [ -L "$target" ]; then
    current=$(readlink "$target" 2>/dev/null || true)
    if [ "$current" = "$source" ]; then
      info "already linked: $target"
      return 0
    fi
  fi

  if [ "$dry_run" -eq 1 ]; then
    info "would link $target -> $source"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  backup_path "$target"
  ln -s "$source" "$target"
  info "linked $target -> $source"
}

manifest_profiles() {
  require_cmd jq
  jq -r '.profiles | keys[]' "$DOTFILES_MANIFEST"
}

validate_profile() {
  local profile=$1
  require_cmd jq
  jq -e --arg profile "$profile" '.profiles[$profile] != null' "$DOTFILES_MANIFEST" >/dev/null \
    || die "unknown profile '$profile' (expected one of: $(manifest_profiles | paste -sd, -))"
}

first_version() {
  local command_name=$1
  local output

  case "$command_name" in
    tmux) output=$("$command_name" -V 2>&1 | head -n 1 || true) ;;
    *) output=$("$command_name" --version 2>&1 | head -n 1 || true) ;;
  esac
  printf '%s\n' "$output"
}
