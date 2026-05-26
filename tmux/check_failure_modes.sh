#!/usr/bin/env bash
set -euo pipefail

# check_failure_modes.sh
# Non-destructive checks for common failure modes and graceful degradation points.
# By default runs read-only checks and reports issues. Nothing is mutated.

ROOT=$(cd "$(dirname "$0")/.." && pwd)

echo "Failure mode checks (read-only)"

# Clipboard tools
echo "\n1) Clipboard tools availability"
for cmd in wl-paste xclip pbpaste clip.exe; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  - $cmd: available"
  else
    echo "  - $cmd: missing"
  fi
done

# TPM/plugins presence
echo "\n2) TPM / plugin checks"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "  - TPM: installed"
else
  echo "  - TPM: not found (~/.tmux/plugins/tpm)"
fi

# tmux-resurrect or restore files
echo "\n3) Restore / resurrect files"
if [ -d "$HOME/.tmux/resurrect" ]; then
  echo "  - resurrect dir found"
  ls -1 "$HOME/.tmux/resurrect" | sed -n '1,10p' || true
else
  echo "  - resurrect dir not found (~/.tmux/resurrect)"
fi

# Check for corrupted restore (best-effort): try reading the first few bytes of files
if [ -d "$HOME/.tmux/resurrect" ]; then
  for f in "$HOME/.tmux/resurrect"/*; do
    [ -f "$f" ] || continue
    head -c 512 "$f" >/dev/null 2>&1 || echo "  - cannot read $f (possible corruption)"
  done
fi

# TPM plugin scripts executable checks (best-effort)
if [ -d "$HOME/.tmux/plugins/tmux-resurrect/scripts" ]; then
  echo "\n4) tmux-resurrect script checks"
  for s in save.sh restore.sh; do
    if [ -x "$HOME/.tmux/plugins/tmux-resurrect/scripts/$s" ]; then
      echo "  - $s: executable"
    else
      echo "  - $s: missing or not executable"
    fi
  done
fi

# Session existence (dry-run) - will not start anything
echo "\n5) Session name collision checks"
EXAMPLES=(default harness_test)
for name in "${EXAMPLES[@]}"; do
  if tmux has-session -t "$name" 2>/dev/null; then
    echo "  - session '$name' already exists"
  else
    echo "  - session '$name' does not exist (ok)"
  fi
done

# Report summary
echo "\nSummary: review missing items above. Scripts are conservative and avoid destructive actions."
