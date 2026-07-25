#!/usr/bin/env bash
set -euo pipefail

tpm="$HOME/.tmux/plugins/tpm/tpm"

[ -x "$tpm" ] || exit 0
exec "$tpm"
