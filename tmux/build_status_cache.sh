#!/usr/bin/env bash
set -euo pipefail

# build_status_cache.sh
# Compose heavy status components into a single cache file for tmux statusbar.
# Intended to be run externally (cron, systemd timer, or invoked manually). Avoids shell-outs inside tmux status.

CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux_status"
TMPFILE=$(mktemp)

# By default do a dry-run; set RUN=1 to actually write the cache file
RUN=${RUN:-0}

# Collectors (add or remove as needed). Keep them fast and minimize network calls.
collect_pomodoro() {
  if [ -x "$HOME/dotfiles/tmux/pomodoro.sh" ]; then
    "$HOME/dotfiles/tmux/pomodoro.sh" || true
  fi
}

collect_random_note() {
  if [ -x "$HOME/dotfiles/tmux/random_note.sh" ]; then
    "$HOME/dotfiles/tmux/random_note.sh" || true
  fi
}

collect_memory_pressure() {
  if command -v free >/dev/null 2>&1; then
    free -m | awk 'NR==2{printf "%.0f", $3/$2*100}'
  fi
}

collect_battery() {
  # Example: try upower or /sys/class/power_supply
  if command -v upower >/dev/null 2>&1; then
    upower -i $(upower -e | grep BAT | head -n1) 2>/dev/null | awk '/percentage/ {print $2}' | tr -d '%'
  fi
}

collect_cpu() {
  # Non-blocking CPU sampling using cached previous values.
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
  PREV_FILE="$CACHE_DIR/cpu_prev"
  mkdir -p "$CACHE_DIR"
  if [ ! -r /proc/stat ]; then
    return
  fi
  read -r cpu a b c d e f g h i j < /proc/stat || return
  idle=$((d + f))
  total=$((a + b + c + d + e + f + g + h + i + j))

  if [ -r "$PREV_FILE" ]; then
    read -r prev_total prev_idle prev_ts < "$PREV_FILE" || true
    # only use prev if it's recent enough (120s)
    now=$(date +%s)
    if [ -n "$prev_ts" ] && [ $((now - prev_ts)) -lt 120 ]; then
      diff_total=$((total - prev_total))
      diff_idle=$((idle - prev_idle))
      if [ "$diff_total" -gt 0 ]; then
        usage=$((100 * (diff_total - diff_idle) / diff_total))
        # write current sample for next run
        printf "%s %s %s" "$total" "$idle" "$now" > "$PREV_FILE" 2>/dev/null || true
        echo "$usage"
        return
      fi
    fi
  fi

  # No usable previous sample: write current and exit empty (so status shows nothing)
  now=$(date +%s)
  printf "%s %s %s" "$total" "$idle" "$now" > "$PREV_FILE" 2>/dev/null || true
  return
}

collect_weather() {
  # Cached external call to wttr.in (very small); keep short timeout and cache externally.
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
  mkdir -p "$CACHE_DIR"
  CACHE="$CACHE_DIR/weather"
  CACHE_TTL=${WEATHER_TTL:-900}

  if [ -r "$CACHE" ]; then
    AGE=$(( $(date +%s) - $(stat -c%Y "$CACHE" 2>/dev/null || stat -f%m "$CACHE" 2>/dev/null || echo 0) ))
    if [ "$AGE" -lt "$CACHE_TTL" ]; then
      cat "$CACHE"
      return
    fi
  fi

  if ! command -v curl >/dev/null 2>&1; then
    return
  fi

  # Try fetch, but do not overwrite cache on failure.
  OUT=$(curl -s --max-time 3 "https://wttr.in/?format=1" 2>/dev/null || true)
  if [ -n "$OUT" ]; then
    printf "%s" "$OUT" > "$CACHE" 2>/dev/null || true
    echo "$OUT"
  else
    # fallback: return old cache if present
    if [ -r "$CACHE" ]; then
      cat "$CACHE"
    fi
  fi
}

collect_todo_count() {
  # Prefer configurable todo file via tmux option @todo_file, else default to a single known path.
  TODO_FILE_DEFAULT="$HOME/Documents/git/scratch/todo.md"
  TODO_FILE="$TODO_FILE_DEFAULT"
  if command -v tmux >/dev/null 2>&1; then
    t=$(tmux show-option -gqv @todo_file 2>/dev/null || true)
    if [ -n "$t" ]; then
      # expand ~ if present
      TODO_FILE=${t/#~/$HOME}
    fi
  fi
  if [ -r "$TODO_FILE" ] && command -v timeout >/dev/null 2>&1; then
    cnt=$(timeout 0.2 grep -cE '^- \[ \]' "$TODO_FILE" 2>/dev/null || true)
    [ -n "$cnt" ] && echo "$cnt"
  fi
}

# Build a single-line status. Keep components optional and small.
{
  echo -n ""
  pn=$(collect_pomodoro 2>/dev/null | tr -d '\n')
  [ -n "$pn" ] && echo -n "$pn "
  rn=$(collect_random_note 2>/dev/null | tr -d '\n')
  [ -n "$rn" ] && echo -n "$rn "
  mem=$(collect_memory_pressure 2>/dev/null)
  [ -n "$mem" ] && echo -n "${mem}% "
  cpu=$(collect_cpu 2>/dev/null)
  [ -n "$cpu" ] && echo -n "CPU ${cpu}% | "
  todo=$(collect_todo_count 2>/dev/null)
  if [ -n "$todo" ]; then
    echo -n "TODO: ${todo} | "
  fi
  bat=$(collect_battery 2>/dev/null)
  [ -n "$bat" ] && echo -n "🔋 ${bat}%"
  # weather last so it can be longer running/cached
  weather=$(collect_weather 2>/dev/null)
  if [ -n "$weather" ]; then
    echo -n " | ${weather}"
  fi
  echo
} > "$TMPFILE"

if [ "$RUN" -eq 1 ]; then
  mkdir -p "$(dirname "$CACHE_FILE")"
  mv "$TMPFILE" "$CACHE_FILE"
  chmod 644 "$CACHE_FILE"
  echo "Wrote cache to $CACHE_FILE"
else
  echo "Dry run — candidate cache contents:"
  cat "$TMPFILE" || true
  rm -f "$TMPFILE"
  echo "To write: RUN=1 $0"
fi
