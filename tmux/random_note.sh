#!/usr/bin/env bash
# random_note.sh — Hardened version
# Safely display a random task from scratch/todo files
# 
# Design:
# - Fail silently if todo directory doesn't exist
# - Timeout after 500ms to prevent blocking status bar
# - Cache results to avoid filesystem scans in hot path
# - Handle missing files gracefully

set +e  # Don't fail on errors (we handle them)

MIN_WIDTH=80
CACHE_FILE="$HOME/.cache/tmux_random_note"
CACHE_TTL=300  # 5 minutes

# Width check
CURRENT_WIDTH=$(tmux display -p '#{client_width}' 2>/dev/null)
if [ "$CURRENT_WIDTH" -lt "$MIN_WIDTH" ]; then
  exit 0
fi

# Check cache first
if [ -r "$CACHE_FILE" ]; then
  CACHE_AGE=$(($(date +%s) - $(stat -f%m "$CACHE_FILE" 2>/dev/null || stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [ "$CACHE_AGE" -lt "$CACHE_TTL" ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Try to find latest todo file (with timeout)
TODO_DIR="$HOME/Documents/git/scratch"
if [ ! -d "$TODO_DIR" ]; then
  echo "" > "$CACHE_FILE"
  exit 0
fi

# Find latest file with timeout
LATEST_FILE=$(timeout 0.2 find "$TODO_DIR" -maxdepth 1 -name 'todo_[0-9][0-9][0-1][0-9][0-3][0-9].md' -print -quit 2>/dev/null | head -n 1)

if [ -z "$LATEST_FILE" ] || [ ! -r "$LATEST_FILE" ]; then
  echo "" > "$CACHE_FILE"
  exit 0
fi

# Parse tasks (with timeout)
OUTPUT=$(timeout 0.3 bash -c '
tasks=()
while IFS= read -r line; do
  if [[ "$line" =~ ^-\ \[\ \]\ ]]; then
    task="${line#- [ ] }"
    tasks+=("$task")
  fi
done < "$1"

if [ ${#tasks[@]} -eq 0 ]; then
  echo "🎧 All done!"
else
  idx=$((RANDOM % ${#tasks[@]}))
  echo "⏰ ${tasks[$idx]}"
fi
' -- "$LATEST_FILE" 2>/dev/null)

if [ -n "$OUTPUT" ]; then
  echo "$OUTPUT" > "$CACHE_FILE"
  cat "$CACHE_FILE"
else
  echo "" > "$CACHE_FILE"
fi

exit 0
