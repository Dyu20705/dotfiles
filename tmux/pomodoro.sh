#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_HOME/dotfiles/tmux"
STATE_FILE="${POMODORO_STATE_FILE:-$STATE_DIR/pomodoro.json}"
mkdir -p "$STATE_DIR"

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'jq is required by pomodoro.sh\n' >&2
    exit 1
  }
}

is_positive_integer() {
  case "$1" in ''|*[!0-9]*|0) return 1 ;; *) return 0 ;; esac
}

notify_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    tmux display-message "$1" 2>/dev/null || true
  fi
}

write_state() {
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/dotfiles-pomodoro.XXXXXX")
  cat > "$tmp"
  mv "$tmp" "$STATE_FILE"
  chmod 600 "$STATE_FILE"
}

start_timer() {
  local sessions=$1 work_min=$2 break_min=$3 now
  is_positive_integer "$sessions" || { printf 'sessions must be a positive integer\n' >&2; exit 2; }
  is_positive_integer "$work_min" || { printf 'work minutes must be a positive integer\n' >&2; exit 2; }
  is_positive_integer "$break_min" || { printf 'break minutes must be a positive integer\n' >&2; exit 2; }
  now=$(date +%s)

  jq -n \
    --argjson sessions "$sessions" \
    --argjson work_seconds "$((work_min * 60))" \
    --argjson break_seconds "$((break_min * 60))" \
    --argjson phase_started "$now" \
    '{schema_version:1,sessions:$sessions,current:1,mode:"work",work_seconds:$work_seconds,break_seconds:$break_seconds,phase_started:$phase_started}' \
    | write_state

  notify_tmux "Pomodoro started: $sessions × ${work_min}/${break_min} min"
}

stop_timer() {
  rm -f "$STATE_FILE"
  notify_tmux 'Pomodoro stopped'
}

show_status() {
  [ -r "$STATE_FILE" ] || exit 0
  jq -e '.schema_version == 1' "$STATE_FILE" >/dev/null || {
    printf 'Invalid Pomodoro state: %s\n' "$STATE_FILE" >&2
    exit 1
  }

  local now state sessions current mode work_seconds break_seconds phase_started duration elapsed remaining
  now=$(date +%s)
  state=$(cat "$STATE_FILE")

  while :; do
    sessions=$(jq -r '.sessions' <<<"$state")
    current=$(jq -r '.current' <<<"$state")
    mode=$(jq -r '.mode' <<<"$state")
    work_seconds=$(jq -r '.work_seconds' <<<"$state")
    break_seconds=$(jq -r '.break_seconds' <<<"$state")
    phase_started=$(jq -r '.phase_started' <<<"$state")

    if [ "$mode" = work ]; then duration=$work_seconds; else duration=$break_seconds; fi
    elapsed=$((now - phase_started))
    [ "$elapsed" -ge "$duration" ] || break

    if [ "$mode" = work ]; then
      state=$(jq --argjson next_started "$((phase_started + duration))" '.mode="break" | .phase_started=$next_started' <<<"$state")
      notify_tmux "Break started: session $current/$sessions"
    elif [ "$current" -ge "$sessions" ]; then
      rm -f "$STATE_FILE"
      notify_tmux 'Pomodoro complete'
      printf 'DONE\n'
      exit 0
    else
      state=$(jq --argjson next_started "$((phase_started + duration))" '.mode="work" | .current += 1 | .phase_started=$next_started' <<<"$state")
      notify_tmux "Work session $((current + 1))/$sessions started"
    fi
  done

  printf '%s\n' "$state" | write_state
  remaining=$((duration - elapsed))
  if [ "$mode" = work ]; then
    printf 'WORK %d/%d %02d:%02d\n' "$current" "$sessions" "$((remaining / 60))" "$((remaining % 60))"
  else
    printf 'BREAK %d/%d %02d:%02d\n' "$current" "$sessions" "$((remaining / 60))" "$((remaining % 60))"
  fi
}

require_jq

case "${1:-status}" in
  start)
    [ $# -eq 4 ] || { printf 'Usage: %s start <sessions> <work-min> <break-min>\n' "$0" >&2; exit 2; }
    start_timer "$2" "$3" "$4"
    ;;
  stop)
    stop_timer
    ;;
  status)
    show_status
    ;;
  *)
    if [ $# -eq 3 ]; then
      start_timer "$1" "$2" "$3"
    else
      printf 'Usage: %s [start <sessions> <work-min> <break-min>|stop|status]\n' "$0" >&2
      exit 2
    fi
    ;;
esac
