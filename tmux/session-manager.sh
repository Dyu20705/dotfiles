#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SESSIONS_DIR="${TMUX_SESSIONS_DIR:-$STATE_HOME/dotfiles/tmux/sessions}"
mkdir -p "$SESSIONS_DIR"

usage() {
  cat <<'EOF'
Usage:
  session-manager.sh create <name> <directory> [description]
  session-manager.sh list
  session-manager.sh restore
  session-manager.sh delete <name>
EOF
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'jq is required for tmux session metadata\n' >&2
    exit 1
  }
}

validate_name() {
  case "$1" in
    ''|*[!A-Za-z0-9._-]*)
      printf 'Invalid session name: %s\n' "$1" >&2
      return 1
      ;;
  esac
}

metadata_path() {
  printf '%s/%s.json\n' "$SESSIONS_DIR" "$1"
}

create_session() {
  local name=$1
  local directory=$2
  local description=${3:-}
  local file tmp

  validate_name "$name"
  [ -d "$directory" ] || { printf 'Directory does not exist: %s\n' "$directory" >&2; return 1; }
  directory=$(cd "$directory" && pwd)

  if tmux has-session -t "=$name" 2>/dev/null; then
    printf 'Session already exists: %s\n' "$name" >&2
    return 1
  fi

  tmux new-session -d -s "$name" -c "$directory"

  file=$(metadata_path "$name")
  tmp=$(mktemp "${TMPDIR:-/tmp}/dotfiles-session.XXXXXX")
  jq -n \
    --arg name "$name" \
    --arg directory "$directory" \
    --arg description "$description" \
    --argjson created "$(date +%s)" \
    '{schema_version:1,name:$name,directory:$directory,description:$description,created:$created}' \
    > "$tmp"
  mv "$tmp" "$file"
  chmod 600 "$file"
  printf 'Created session: %s (%s)\n' "$name" "$directory"
}

list_sessions() {
  printf 'Active tmux sessions:\n'
  tmux list-sessions -F '  #{session_name} | #{session_windows} windows | #{session_path}' 2>/dev/null \
    || printf '  <none>\n'

  printf '\nSaved session metadata:\n'
  local found=0 file
  while IFS= read -r -d '' file; do
    found=1
    jq -r '"  \(.name) | \(.directory) | \(.description // "")"' "$file" \
      || printf '  invalid metadata: %s\n' "$file" >&2
  done < <(find "$SESSIONS_DIR" -maxdepth 1 -type f -name '*.json' -print0 | sort -z)
  [ "$found" -eq 1 ] || printf '  <none>\n'
}

restore_sessions() {
  local file name directory
  while IFS= read -r -d '' file; do
    if ! jq -e '.schema_version == 1 and (.name | type == "string") and (.directory | type == "string")' "$file" >/dev/null; then
      printf 'Skipping invalid metadata: %s\n' "$file" >&2
      continue
    fi

    name=$(jq -r '.name' "$file")
    directory=$(jq -r '.directory' "$file")
    validate_name "$name" || continue

    if [ ! -d "$directory" ]; then
      printf 'Skipping %s; directory missing: %s\n' "$name" "$directory" >&2
      continue
    fi

    if ! tmux has-session -t "=$name" 2>/dev/null; then
      tmux new-session -d -s "$name" -c "$directory"
      printf 'Restored session: %s\n' "$name"
    fi
  done < <(find "$SESSIONS_DIR" -maxdepth 1 -type f -name '*.json' -print0 | sort -z)
}

delete_session() {
  local name=$1
  validate_name "$name"

  if tmux has-session -t "=$name" 2>/dev/null; then
    tmux kill-session -t "=$name"
  fi
  rm -f "$(metadata_path "$name")"
  printf 'Deleted session: %s\n' "$name"
}

require_jq

case "${1:-list}" in
  create)
    [ $# -ge 3 ] || { usage >&2; exit 2; }
    create_session "$2" "$3" "${4:-}"
    ;;
  list)
    list_sessions
    ;;
  restore)
    restore_sessions
    ;;
  delete)
    [ $# -eq 2 ] || { usage >&2; exit 2; }
    delete_session "$2"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
