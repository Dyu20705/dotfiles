#!/usr/bin/env bash
# pomodoro.sh — Hardened version (Deterministic Session Timer)
#
# Design:
# - Store state in JSON cache file (simple format, jq optional)
# - Graceful fallback if jq not available
# - Timeout on sound playback to prevent blocking
# - Fail silently if dependencies missing
#
# Usage:
#   pomodoro.sh <sessions> <work_min> <break_min>   # Start
#   pomodoro.sh stop                                  # Stop
#   pomodoro.sh                                       # Display status

set +e

OS="$(uname)"

# Sound playback with timeout (don't block tmux)
play_sound() {
  local file="$HOME/dotfiles/tmux/Ringing.mp3"
  [ ! -f "$file" ] && return 0
  
  if [ "$OS" = "Darwin" ]; then
    timeout 2 afplay "$file" &>/dev/null &
  else
    timeout 2 paplay "$file" 2>/dev/null &
  fi
}

STATE_FILE="$HOME/.cache/pomo.json"
mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null

# Start new pomodoro session
if [ $# -eq 3 ]; then
  SESSIONS=$1
  WORK_MIN=$2
  BREAK_MIN=$3

  # Try to use jq if available, fallback to printf
  if command -v jq &>/dev/null; then
    jq -n \
      --argjson sessions "$SESSIONS" \
      --argjson work "$((WORK_MIN * 60))" \
      --argjson break "$((BREAK_MIN * 60))" \
      --argjson current 1 \
      --arg mode "work" \
      --argjson start "$(date +%s)" \
      '{sessions: $sessions, work: $work, break: $break, current: $current, mode: $mode, start: $start}' > "$STATE_FILE" 2>/dev/null
  else
    # Fallback: simple JSON format
    printf '{"sessions":%d,"work":%d,"break":%d,"current":1,"mode":"work","start":%d}\n' \
      "$SESSIONS" "$((WORK_MIN * 60))" "$((BREAK_MIN * 60))" "$(date +%s)" > "$STATE_FILE" 2>/dev/null
  fi

  tmux display-message "👨‍💻 Pomodoro: $SESSIONS x ($WORK_MIN/$BREAK_MIN min)" 2>/dev/null
  exit 0
fi

# Stop pomodoro
if [ "${1:-}" = "stop" ]; then
  rm -f "$STATE_FILE"
  tmux display-message "Pomodoro stopped" 2>/dev/null
  exit 0
fi

# Display current status
[ ! -f "$STATE_FILE" ] && exit 0

# Parse and display (with timeout)
timeout 0.15 bash -c '
  state=$(cat "$1" 2>/dev/null)
  [ -z "$state" ] && exit 0
  
  if command -v jq &>/dev/null; then
    current=$(echo "$state" | jq -r ".current // 1" 2>/dev/null)
    sessions=$(echo "$state" | jq -r ".sessions // 1" 2>/dev/null)
    mode=$(echo "$state" | jq -r ".mode // \"work\"" 2>/dev/null)
    start=$(echo "$state" | jq -r ".start // 0" 2>/dev/null)
  else
    # Fallback parsing without jq (simple extraction)
    current=$(echo "$state" | grep -o "\"current\":[0-9]*" | cut -d: -f2)
    sessions=$(echo "$state" | grep -o "\"sessions\":[0-9]*" | cut -d: -f2)
    mode=$(echo "$state" | grep -o "\"mode\":\"[^\"]*" | cut -d: -f2 | tr -d "\"")
    start=$(echo "$state" | grep -o "\"start\":[0-9]*" | cut -d: -f2)
  fi
  
  [ -z "$current" ] && exit 0
  
  elapsed=$(($(date +%s) - start))
  icon=$([ "$mode" = "work" ] && echo "🍅" || echo "☕")
  printf "%s %d/%d +%dm\n" "$icon" "$current" "$sessions" "$((elapsed / 60))"
' -- "$STATE_FILE" 2>/dev/null

exit 0
