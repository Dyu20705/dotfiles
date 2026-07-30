#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
failures=0

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  failures=$((failures + 1))
}

while IFS= read -r workflow; do
  if grep -En \
    '^[[:space:]]*- uses: [^#[:space:]]+@(v[0-9]+|main|master|latest)([[:space:]]|$)' \
    "$workflow"; then
    fail "mutable action: $workflow"
  fi
done < <(
  find "$ROOT/.github/workflows" \
    -type f \( -name '*.yml' -o -name '*.yaml' \) -print
)

while IFS= read -r tracked; do
  case "$tracked" in
    *.example|*.sample|*.template) continue ;;
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.secret|*.token|credentials.json)
      fail "credential-like tracked file: $tracked"
      ;;
  esac
done < <(git -C "$ROOT" ls-files)

private_key_matches=$(
  git -C "$ROOT" grep -InE \
    'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY' -- \
    . ':!scripts/security-check.sh' 2>/dev/null || true
)
if [ -n "$private_key_matches" ]; then
  printf '%s\n' "$private_key_matches" >&2
  fail 'tracked private-key marker'
fi

token_matches=$(
  git -C "$ROOT" grep -InE \
    '(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{50,}|A(KIA|SIA)[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{20,})' -- \
    . ':!scripts/security-check.sh' 2>/dev/null || true
)
if [ -n "$token_matches" ]; then
  printf '%s\n' "$token_matches" >&2
  fail 'tracked token-like value'
fi

personal_path_matches=$(
  git -C "$ROOT" grep -InE \
    '(/home/[^/$[:space:]]+/|/Users/[^/$[:space:]]+/|[A-Za-z]:\\Users\\[^\\[:space:]]+\\)' -- \
    . \
    ':!scripts/security-check.sh' \
    ':!scripts/test.sh' \
    ':!scripts/tests/**' 2>/dev/null || true
)
if [ -n "$personal_path_matches" ]; then
  printf '%s\n' "$personal_path_matches" >&2
  fail 'tracked personal absolute path'
fi

if git config --file "$ROOT/git/.gitconfig" --get user.name >/dev/null 2>&1; then
  fail 'tracked Git name'
fi
if git config --file "$ROOT/git/.gitconfig" --get user.email >/dev/null 2>&1; then
  fail 'tracked Git email'
fi
if git config --file "$ROOT/git/.gitconfig" --get user.signingkey >/dev/null 2>&1; then
  fail 'tracked signing key'
fi

printf 'Security baseline: %d failure(s)\n' "$failures"
[ "$failures" -eq 0 ]
