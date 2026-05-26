#!/usr/bin/env bash
set -euo pipefail

# test_harness.sh
# Lightweight test harness to exercise isolated tmux sockets and report observability options.
# By default this script runs in DRY_RUN mode (does not start tmux). Set RUN=1 to execute.

RUN=${RUN:-0}
TMUX_LABEL=${TMUX_LABEL:-dotfiles_test}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Test harness workspace: $ROOT"

echo "Preparing temporary config in $TMPDIR"
cp "$ROOT/tmux/tmux.conf" "$TMPDIR/tmux.conf" 2>/dev/null || true
cp "$ROOT/tmux/base.conf" "$TMPDIR/base.conf" 2>/dev/null || true
cp "$ROOT/tmux/workflow.conf" "$TMPDIR/workflow.conf" 2>/dev/null || true
cp "$ROOT/tmux/session.conf" "$TMPDIR/session.conf" 2>/dev/null || true
cp "$ROOT/tmux/ui.conf" "$TMPDIR/ui.conf" 2>/dev/null || true
cp "$ROOT/tmux/plugins.conf" "$TMPDIR/plugins.conf" 2>/dev/null || true
cp "$ROOT/tmux/observability.conf" "$TMPDIR/observability.conf" 2>/dev/null || true

# Ensure the copied top-level config references the TMPDIR versions (best-effort)
cat > "$TMPDIR/tmux.conf" <<EOF
run-shell -b '
config_path="${TMPDIR}/tmux.conf"
config_dir="${TMPDIR}"
tmux set-option -gq @tmux_root "${TMPDIR}"
# Source a minimal, isolated set
tmux source-file "${TMPDIR}/base.conf"
tmux source-file "${TMPDIR}/workflow.conf"
tmux source-file "${TMPDIR}/session.conf"
tmux source-file "${TMPDIR}/ui.conf"
tmux source-file "${TMPDIR}/plugins.conf"
# Observability
tmux source-file "${TMPDIR}/observability.conf"
'
EOF

TMUX_CMD=(tmux -L "$TMUX_LABEL" -f "$TMPDIR/tmux.conf")

if [ "$RUN" -ne 1 ]; then
  echo "DRY RUN (no tmux actions). To run: RUN=1 $0"
  echo "Planned actions:"
  echo "  - Start tmux server on socket name: $TMUX_LABEL"
  echo "  - Create detached session: harness_test"
  echo "  - Query: @tmux_active_socket @tmux_config @tmux_config_hash @tmux_nested @tmux_nested_level"
  exit 0
fi

# Start server and create session
echo "Starting tmux server (socket: $TMUX_LABEL)"
"${TMUX_CMD[@]}" new-session -d -s harness_test -c /tmp || { echo "Failed to start session"; exit 2; }

# Query observability keys
for key in @tmux_active_socket @tmux_config @tmux_config_hash @tmux_nested @tmux_nested_level @tmux_session_name @tmux_session_windows @tmux_client_pid @tmux_client_tty; do
  val=$("${TMUX_CMD[@]}" show-options -gqv "$key" 2>/dev/null || true)
  printf "%-24s: %s\n" "$key" "${val:-<unset>}"
done

# Clean up
echo "Killing test server"
"${TMUX_CMD[@]}" kill-server || true

echo "Done"
