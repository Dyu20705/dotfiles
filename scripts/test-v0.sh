#!/usr/bin/env bash
set -uo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
failures=0

for test_file in \
  "$ROOT/scripts/tests/v0_contract_test.sh" \
  "$ROOT/scripts/tests/backup_restore_test.sh" \
  "$ROOT/scripts/tests/dev_test.sh" \
  "$ROOT/scripts/tests/gw_test.sh" \
  "$ROOT/scripts/tests/capability_test.sh"
do
  name=${test_file##*/}
  if DOTFILES_ROOT="$ROOT" bash "$test_file"; then
    printf '[PASS] %s\n' "$name"
  else
    printf '[FAIL] %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
done

printf '\nV0 result: %d failure(s)\n' "$failures"
[ "$failures" -eq 0 ]
