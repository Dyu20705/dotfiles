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
  # lightweight /proc sampling: take two samples 0.1s apart
  if [ -r /proc/stat ]; then
    read -r cpu a b c d e f g h i j < /proc/stat || return
    prev_idle=$((d + f))
    prev_total=$((a + b + c + d + e + f + g + h + i + j))
    sleep 0.1
    read -r cpu2 a2 b2 c2 d2 e2 f2 g2 h2 i2 j2 < /proc/stat || return
    idle=$((d2 + f2))
    total=$((a2 + b2 + c2 + d2 + e2 + f2 + g2 + h2 + i2 + j2))
    diff_idle=$((idle - prev_idle))
    diff_total=$((total - prev_total))
    if [ "$diff_total" -gt 0 ]; then
      usage=$((100 * (diff_total - diff_idle) / diff_total))
      echo "$usage"
    fi
  fi
}

collect_weather() {
  # Cached external call to wttr.in (very small); keep short timeout and cache externally
  CACHE="$XDG_CACHE_HOME"/tmux_weather_cache
  CACHE_TTL=${WEATHER_TTL:-900}
  if [ -r "$CACHE" ]; then
    AGE=$(( $(date +%s) - $(stat -c%Y "$CACHE" 2>/dev/null || stat -f%m "$CACHE" 2>/dev/null || echo 0) ))
    if [ "$AGE" -lt "$CACHE_TTL" ]; then
      cat "$CACHE"
      return
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    OUT=$(curl -s --max-time 3 "https://wttr.in/?format=1" 2>/dev/null || true)
    if [ -n "$OUT" ]; then
      printf "%s" "$OUT" > "$CACHE" 2>/dev/null || true
      echo "$OUT"
    fi
  fi
}

collect_todo_count() {
  TODO_DIR="$HOME/Documents/git/scratch"
  if [ -d "$TODO_DIR" ] && command -v timeout >/dev/null 2>&1; then
    LATEST=$(timeout 0.2 find "$TODO_DIR" -maxdepth 1 -name 'todo_*.md' -print -quit 2>/dev/null | head -n1)
    if [ -n "$LATEST" ] && [ -r "$LATEST" ]; then
      cnt=$(timeout 0.2 grep -cE '^- \[ \]' "$LATEST" 2>/dev/null || true)
      [ -n "$cnt" ] && echo "$cnt"
    fi
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
