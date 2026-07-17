#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="${TMUX_CACHE_DIR:-$CACHE_HOME/dotfiles/tmux}"
CACHE_FILE="${TMUX_STATUS_CACHE:-$CACHE_DIR/status.txt}"
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/dotfiles-tmux-status.XXXXXX")
trap 'rm -f "$TMPFILE"' EXIT
RUN=${RUN:-0}

collect_pomodoro() {
  [ -x "$SCRIPT_DIR/pomodoro.sh" ] && "$SCRIPT_DIR/pomodoro.sh" || true
}

collect_random_note() {
  [ "${DOTFILES_STATUS_RANDOM_NOTE:-0}" = 1 ] || return 0
  [ -x "$SCRIPT_DIR/random_note.sh" ] && "$SCRIPT_DIR/random_note.sh" || true
}

collect_memory_pressure() {
  if command -v free >/dev/null 2>&1; then
    free -m | awk 'NR==2 && $2>0 {printf "MEM %.0f%%", $3/$2*100}'
  fi
}

collect_battery() {
  if command -v pmset >/dev/null 2>&1; then
    pmset -g batt 2>/dev/null | awk -F';' 'NR==2 {gsub(/[^0-9%]/,"",$1); print $1}'
    return
  fi

  for capacity in /sys/class/power_supply/BAT*/capacity; do
    [ -r "$capacity" ] || continue
    cat "$capacity"
    return
  done
}

collect_cpu() {
  [ -r /proc/stat ] || return 0

  local prev_file="$CACHE_DIR/cpu-prev" now
  local cpu user nice system idle iowait irq softirq steal guest guest_nice
  local total idle_all prev_total prev_idle prev_time diff_total diff_idle

  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat || return 0
  idle_all=$((idle + iowait))
  total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
  now=$(date +%s)

  if [ -r "$prev_file" ]; then
    read -r prev_total prev_idle prev_time < "$prev_file" || true
    if [ -n "${prev_time:-}" ] && [ $((now - prev_time)) -lt 300 ]; then
      diff_total=$((total - prev_total))
      diff_idle=$((idle_all - prev_idle))
      if [ "$diff_total" -gt 0 ]; then
        printf 'CPU %d%%' "$((100 * (diff_total - diff_idle) / diff_total))"
      fi
    fi
  fi

  printf '%s %s %s\n' "$total" "$idle_all" "$now" > "$prev_file"
}

collect_weather() {
  [ "${DOTFILES_STATUS_WEATHER:-0}" = 1 ] || return 0
  command -v curl >/dev/null 2>&1 || return 0

  local cache="$CACHE_DIR/weather.txt"
  local ttl=${WEATHER_TTL:-900}
  local now age mtime output
  now=$(date +%s)

  if [ -r "$cache" ]; then
    mtime=$(stat -c %Y "$cache" 2>/dev/null || stat -f %m "$cache" 2>/dev/null || printf 0)
    age=$((now - mtime))
    if [ "$age" -lt "$ttl" ]; then
      cat "$cache"
      return
    fi
  fi

  output=$(curl -fsS --max-time 3 'https://wttr.in/?format=1' 2>/dev/null || true)
  if [ -n "$output" ]; then
    printf '%s' "$output" > "$cache"
    printf '%s' "$output"
  elif [ -r "$cache" ]; then
    cat "$cache"
  fi
}

collect_todo_count() {
  local todo_file="${DOTFILES_TODO_FILE:-}"
  local configured=""
  if command -v tmux >/dev/null 2>&1; then
    configured=$(tmux show-option -gqv @todo_file 2>/dev/null || true)
    [ -n "$configured" ] && todo_file=${configured/#\~/$HOME}
  fi
  [ -n "$todo_file" ] && [ -r "$todo_file" ] || return 0
  grep -cE '^- \[ \]' "$todo_file" 2>/dev/null || true
}

mkdir -p "$CACHE_DIR"

components=()
for collector in collect_pomodoro collect_random_note collect_memory_pressure collect_cpu; do
  value=$($collector 2>/dev/null | tr -d '\n')
  [ -n "$value" ] && components+=("$value")
done

todo=$(collect_todo_count 2>/dev/null | tr -d '\n')
[ -n "$todo" ] && components+=("TODO $todo")

battery=$(collect_battery 2>/dev/null | tr -d '\n')
[ -n "$battery" ] && components+=("BAT ${battery%%%}%")

weather=$(collect_weather 2>/dev/null | tr -d '\n')
[ -n "$weather" ] && components+=("$weather")

(IFS=' | '; printf '%s\n' "${components[*]}") > "$TMPFILE"

if [ "$RUN" -eq 1 ]; then
  mv "$TMPFILE" "$CACHE_FILE"
  chmod 600 "$CACHE_FILE"
  trap - EXIT
  printf 'Wrote %s\n' "$CACHE_FILE"
else
  cat "$TMPFILE"
fi
