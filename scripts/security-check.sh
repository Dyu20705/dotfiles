#!/usr/bin/env bash
set -euo pipefail
ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
failures=0
fail() { printf '[FAIL] %s\n' "$1" >&2; failures=$((failures + 1)); }
while IFS= read -r workflow; do
  grep -En '^[[:space:]]*- uses: [^#[:space:]]+@(v[0-9]+|main|master|latest)([[:space:]]|$)' "$workflow" && fail "mutable action: $workflow" || true
done < <(find "$ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print)
git -C "$ROOT" grep -IlE 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' -- . && fail 'tracked private key marker' || true
if git config --file "$ROOT/git/.gitconfig" --get user.email >/dev/null 2>&1; then fail 'tracked Git email'; fi
if git config --file "$ROOT/git/.gitconfig" --get user.signingkey >/dev/null 2>&1; then fail 'tracked signing key'; fi
printf 'Security baseline: %d failure(s)\n' "$failures"
[ "$failures" -eq 0 ]
