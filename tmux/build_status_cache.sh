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

# Build a single-line status. Keep components optional and small.
{
  echo -n ""
  pn=$(collect_pomodoro 2>/dev/null | tr -d '\n')
  [ -n "$pn" ] && echo -n "$pn "
  rn=$(collect_random_note 2>/dev/null | tr -d '\n')
  [ -n "$rn" ] && echo -n "$rn "
  mem=$(collect_memory_pressure 2>/dev/null)
  [ -n "$mem" ] && echo -n "${mem}% "
  bat=$(collect_battery 2>/dev/null)
  [ -n "$bat" ] && echo -n "${bat}%"
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
