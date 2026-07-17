#!/usr/bin/env bash
set -u

MIN_WIDTH=${DOTFILES_RANDOM_NOTE_MIN_WIDTH:-80}
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="$CACHE_HOME/dotfiles/tmux"
CACHE_FILE="$CACHE_DIR/random-note.txt"
CACHE_TTL=${DOTFILES_RANDOM_NOTE_TTL:-300}
TODO_DIR=${DOTFILES_TODO_DIR:-}

if [ -z "$TODO_DIR" ] && command -v tmux >/dev/null 2>&1; then
  TODO_DIR=$(tmux show-option -gqv @todo_dir 2>/dev/null || true)
  TODO_DIR=${TODO_DIR/#\~/$HOME}
fi

[ -n "$TODO_DIR" ] && [ -d "$TODO_DIR" ] || exit 0
mkdir -p "$CACHE_DIR"

current_width=$(tmux display -p '#{client_width}' 2>/dev/null || printf 0)
case "$current_width" in ''|*[!0-9]*) current_width=0 ;; esac
[ "$current_width" -ge "$MIN_WIDTH" ] || exit 0

if [ -r "$CACHE_FILE" ]; then
  mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || printf 0)
  age=$(( $(date +%s) - mtime ))
  if [ "$age" -lt "$CACHE_TTL" ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

latest_file=$(find "$TODO_DIR" -maxdepth 1 -type f -name 'todo_*.md' -print 2>/dev/null | sort -r | head -n 1)
[ -n "$latest_file" ] && [ -r "$latest_file" ] || exit 0

output=$(awk '
  /^- \[ \] / { tasks[++count] = substr($0, 7) }
  END {
    if (count > 0) {
      srand()
      print "TODO " tasks[1 + int(rand() * count)]
    }
  }
' "$latest_file")

[ -n "$output" ] || exit 0
printf '%s\n' "$output" > "$CACHE_FILE"
chmod 600 "$CACHE_FILE"
printf '%s\n' "$output"
