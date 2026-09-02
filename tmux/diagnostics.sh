#!/usr/bin/env bash
# tmux-diagnostics.sh
#
# Measure tmux startup time and identify bottlenecks
#
# Usage:
#   tmux-diagnostics.sh              # Run all diagnostics
#   tmux-diagnostics.sh startup      # Measure startup time
#   tmux-diagnostics.sh shells       # Count shell invocations

set +e

TMUX_CONF_PATH="${TMUX_CONF_PATH:-$PWD/tmux/tmux.conf}"

measure_startup() {
  echo "Tmux startup diagnostics:"

  # Create a temporary config
  TMPDIR=$(mktemp -d)
  TMPCONF="$TMPDIR/tmux.conf"
  cp "$TMUX_CONF_PATH" "$TMPCONF"
  cp "$PWD/tmux/base.conf" "$TMPDIR/base.conf"
  cp "$PWD/tmux/workflow.conf" "$TMPDIR/workflow.conf"
  cp "$PWD/tmux/session.conf" "$TMPDIR/session.conf"
  cp "$PWD/tmux/ui.conf" "$TMPDIR/ui.conf"
  cp "$PWD/tmux/plugins.conf" "$TMPDIR/plugins.conf"
  cp "$PWD/tmux/clipboard-paste.sh" "$TMPDIR/clipboard-paste.sh"
  chmod +x "$TMPDIR/clipboard-paste.sh"

  # Measure with full config
  echo "1. Full config load:"
  START=$(date +%s%3N)
  tmux -f "$TMPCONF" new-session -d -s diagtest$$ -c /tmp 2>/dev/null
  END=$(date +%s%3N)
  echo "   Time: $((END - START))ms"
  tmux kill-session -t diagtest$$ 2>/dev/null

  # Measure with plugins disabled
  : > "$TMPDIR/plugins.conf"
  echo "2. Without plugins:"
  START=$(date +%s%3N)
  tmux -f "$TMPCONF" new-session -d -s diagtest2$$ -c /tmp 2>/dev/null
  END=$(date +%s%3N)
  echo "   Time: $((END - START))ms"
  tmux kill-session -t diagtest2$$ 2>/dev/null

  # Measure with status bar disabled
  cp "$TMPCONF" "$TMPDIR/tmux.nostatus"
  echo "set -g status off" >> "$TMPDIR/tmux.nostatus"
  echo "3. Status bar disabled:"
  START=$(date +%s%3N)
  tmux -f "$TMPDIR/tmux.nostatus" new-session -d -s diagtest3$$ -c /tmp 2>/dev/null
  END=$(date +%s%3N)
  echo "   Time: $((END - START))ms"
  tmux kill-session -t diagtest3$$ 2>/dev/null

  rm -rf "$TMPDIR"

  echo ""
  echo "Diagnostics complete"
}

check_shell_invocations() {
  echo "Shell invocation check:"
  echo ""
  echo "1. Status bar shell-outs (status-right/left):"
  grep -R -nE '#\(|run-shell|run ' "$PWD/tmux"/*.conf 2>/dev/null | wc -l
  echo ""

  echo "2. Configured plugins:"
  grep -c "@plugin" "$PWD/tmux/plugins.conf"
  echo ""

  echo "3. Key bindings with shell execution:"
  grep -R -nE 'bind .*run-shell|bind .*run ' "$PWD/tmux"/*.conf 2>/dev/null | wc -l
  echo ""

  echo "Hot path summary:"
  echo "  - Status bar now uses tmux-native formats only"
  echo "  - Clipboard and session actions remain explicit bindings"
  echo "  - Plugin loading is isolated in plugins.conf"
  echo ""
}

check_nested_tmux() {
  echo "Nested tmux check:"
  echo ""
  if [ -n "$TMUX" ]; then
    echo "Already in tmux. Config escape-time: $(tmux show-option -g escape-time | awk '{print $2}')"
    echo "Observability options (if present):"
    tmux show-options -gqv @tmux_active_socket 2>/dev/null || true && echo "  active_socket: $(tmux show-options -gqv @tmux_active_socket 2>/dev/null)"
    tmux show-options -gqv @tmux_config 2>/dev/null && echo "  config: $(tmux show-options -gqv @tmux_config 2>/dev/null)"
    tmux show-options -gqv @tmux_nested 2>/dev/null && echo "  nested: $(tmux show-options -gqv @tmux_nested 2>/dev/null)"
    tmux show-options -gqv @tmux_ssh 2>/dev/null && echo "  ssh: $(tmux show-options -gqv @tmux_ssh 2>/dev/null)"
  else
    echo "Not in tmux session. Create one to test nested behavior."
    echo ""
    echo "To test: tmux new-session; tmux attach-session; run: TMUX=1 tmux new-session -d -s nested"
  fi
}

check_config_path() {
  echo "Config path:"
  echo "$TMUX_CONF_PATH"
}

check_config_checksum() {
  echo "Config checksum:"
  if command -v tmux >/dev/null 2>&1; then
    cfg=$(tmux display -p "#{config_file}" 2>/dev/null || echo "$TMUX_CONF_PATH")
    echo "Config: $cfg"
    if [ -f "$cfg" ]; then
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$cfg"
      elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$cfg"
      else
        echo "No sha256 utility found to compute checksum"
      fi
    else
      echo "Config file not found: $cfg"
    fi
  else
    echo "tmux not available"
  fi
}

check_status_shellouts() {
  echo "Status shell-outs audit:"
  echo "Searching tmux directory for '#(' occurrences (possible shell-outs)..."
  grep -R --line-number "#(" "$PWD/tmux" 2>/dev/null || echo "  none found in tmux/"
}

case "${1:-all}" in
  startup)
    measure_startup
    ;;
  shells)
    check_shell_invocations
    ;;
  nested)
    check_nested_tmux
    ;;
  checksum)
    check_config_checksum
    ;;
  audit)
    check_status_shellouts
    ;;
  config)
    check_config_path
    ;;
  all)
    measure_startup
    echo ""
    check_shell_invocations
    echo ""
    check_nested_tmux
    echo ""
    check_config_path
    echo ""
    check_config_checksum
    echo ""
    check_status_shellouts
    ;;
  *)
    echo "Usage: $0 [startup|shells|nested|config|all]"
    exit 1
    ;;
esac
