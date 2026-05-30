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

get_state_value() {
  local state_key=$1
  local state_json=$2

  if command -v jq >/dev/null 2>&1; then
    jq -r ".$state_key // empty" <<<"$state_json" 2>/dev/null
    return
  fi

  case "$state_key" in
    current) printf '%s' "$state_json" | grep -o '"current":[0-9]*' | cut -d: -f2 ;;
    sessions) printf '%s' "$state_json" | grep -o '"sessions":[0-9]*' | cut -d: -f2 ;;
    mode) printf '%s' "$state_json" | grep -o '"mode":"[^"]*' | cut -d: -f2 | tr -d '"' ;;
    start) printf '%s' "$state_json" | grep -o '"start":[0-9]*' | cut -d: -f2 ;;
  esac
}

state=$(timeout 0.15 cat "$STATE_FILE" 2>/dev/null)
[ -z "$state" ] && exit 0

current=$(get_state_value current "$state")
sessions=$(get_state_value sessions "$state")
mode=$(get_state_value mode "$state")
start=$(get_state_value start "$state")

[ -z "$current" ] && exit 0

elapsed=$(( $(date +%s) - start ))
if [ "$mode" = "work" ]; then
  icon="🍅"
else
  icon="☕"
fi
printf '%s %d/%d +%dm\n' "$icon" "$current" "$sessions" "$((elapsed / 60))"

exit 0
