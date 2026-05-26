#!/usr/bin/env bash
# tmux-session-manager.sh
# 
# Deterministic session lifecycle management
# Goals:
# - Create named sessions with clear purpose
# - Restore sessions in deterministic order
# - Show session context (project, branch, workspace)
# 
# Usage:
#   tmux-session-manager.sh create <name> <directory> [description]
#   tmux-session-manager.sh list
#   tmux-session-manager.sh restore
#   tmux-session-manager.sh delete <name>

set +e

SESSIONS_DIR="$HOME/.cache/tmux_sessions"
mkdir -p "$SESSIONS_DIR"

read_session_field() {
  local file="$1"
  local field="$2"

  python3 - "$file" "$field" <<'PY'
import json
import sys

path = sys.argv[1]
field = sys.argv[2]

with open(path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)

value = data.get(field, '')
if value is None:
    value = ''

print(value)
PY
}

create_session() {
  local name="$1"
  local dir="$2"
  local desc="${3:-}"
  
  # Create tmux session
  tmux new-session -d -s "$name" -c "$dir" 2>/dev/null || {
    echo "✗ Failed to create session '$name'"
    return 1
  }
  
  # Save metadata
  cat > "$SESSIONS_DIR/$name" <<EOF
{
  "name": "$name",
  "directory": "$dir",
  "description": "$desc",
  "created": $(date +%s)
}
EOF
  
  echo "✔ Session '$name' created"
}

list_sessions() {
  echo "Active TMux Sessions:"
  tmux list-sessions -F "#{session_name} (#{session_windows} windows)" 2>/dev/null
  
  if [ -d "$SESSIONS_DIR" ]; then
    echo ""
    echo "Saved Session Metadata:"
    find "$SESSIONS_DIR" -maxdepth 1 -type f -print0 2>/dev/null | sort -z |
      while IFS= read -r -d '' session_file; do
        name=$(read_session_field "$session_file" name)
        dir=$(read_session_field "$session_file" directory)
        desc=$(read_session_field "$session_file" description)
        [ -n "$name" ] && printf '%s | %s | %s\n' "$name" "$dir" "$desc"
      done
  fi
}

restore_sessions() {
  if [ ! -d "$SESSIONS_DIR" ]; then
    echo "No saved sessions"
    return
  fi
  
  find "$SESSIONS_DIR" -maxdepth 1 -type f -print0 2>/dev/null | sort -z |
    while IFS= read -r -d '' session_file; do
      name=$(read_session_field "$session_file" name)
      dir=$(read_session_field "$session_file" directory)

      [ -z "$name" ] && continue
      [ -z "$dir" ] && dir="$HOME"

      # Restore if session doesn't exist.
      if ! tmux has-session -t "$name" 2>/dev/null; then
        tmux new-session -d -s "$name" -c "$dir"
        echo "Restored session: $name"
      fi
    done
}

delete_session() {
  local name="$1"
  tmux kill-session -t "$name" 2>/dev/null
  rm -f "$SESSIONS_DIR/$name"
  echo "✔ Session '$name' deleted"
}

case "${1:-list}" in
  create)
    [ $# -lt 2 ] && { echo "Usage: $0 create <name> <dir> [description]"; exit 1; }
    create_session "$2" "$3" "$4"
    ;;
  list)
    list_sessions
    ;;
  restore)
    restore_sessions
    ;;
  delete)
    [ -z "$2" ] && { echo "Usage: $0 delete <name>"; exit 1; }
    delete_session "$2"
    ;;
  *)
    echo "Unknown command: $1"
    exit 1
    ;;
esac
