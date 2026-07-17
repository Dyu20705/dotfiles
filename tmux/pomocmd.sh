#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT=${1:-}
DEFAULT_WORK=30
DEFAULT_BREAK=5
DEFAULT_SESSIONS=4

INPUT=${INPUT//,/ }
read -r sessions work break_minutes <<<"$INPUT"
sessions=${sessions:-$DEFAULT_SESSIONS}
work=${work:-$DEFAULT_WORK}
break_minutes=${break_minutes:-$DEFAULT_BREAK}

exec "$SCRIPT_DIR/pomodoro.sh" start "$sessions" "$work" "$break_minutes"
