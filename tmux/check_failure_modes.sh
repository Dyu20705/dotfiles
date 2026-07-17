#!/usr/bin/env bash
set -euo pipefail

# Non-destructive checks for common failure modes and graceful degradation.

echo "Failure mode checks (read-only)"

printf '\n1) Clipboard tools availability\n'
for cmd in wl-paste xclip pbpaste clip.exe; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  - $cmd: available"
  else
    echo "  - $cmd: missing"
  fi
done

printf '\n2) TPM / plugin checks\n'
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "  - TPM: installed"
else
  echo "  - TPM: not found (~/.tmux/plugins/tpm)"
fi

printf '\n3) Restore / resurrect files\n'
if [ -d "$HOME/.tmux/resurrect" ]; then
  echo "  - resurrect dir found"
  find "$HOME/.tmux/resurrect" -maxdepth 1 -type f | sed -n '1,10p' || true
else
  echo "  - resurrect dir not found (~/.tmux/resurrect)"
fi

if [ -d "$HOME/.tmux/resurrect" ]; then
  for file in "$HOME/.tmux/resurrect"/*; do
    [ -f "$file" ] || continue
    head -c 512 "$file" >/dev/null 2>&1 \
      || echo "  - cannot read $file (possible corruption)"
  done
fi

if [ -d "$HOME/.tmux/plugins/tmux-resurrect/scripts" ]; then
  printf '\n4) tmux-resurrect script checks\n'
  for script in save.sh restore.sh; do
    if [ -x "$HOME/.tmux/plugins/tmux-resurrect/scripts/$script" ]; then
      echo "  - $script: executable"
    else
      echo "  - $script: missing or not executable"
    fi
  done
fi

printf '\n5) Session name collision checks\n'
examples=(default harness_test)
for name in "${examples[@]}"; do
  if tmux has-session -t "=$name" 2>/dev/null; then
    echo "  - session '$name' already exists"
  else
    echo "  - session '$name' does not exist (ok)"
  fi
done

printf '\nSummary: review missing items above; no changes were made.\n'
