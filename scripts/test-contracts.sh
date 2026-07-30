#!/usr/bin/env bash
set -uo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
failures=0

tests=(
  repository_contract_test.sh
  operator_contract_test.sh
  backup_restore_test.sh
  dev_test.sh
  gw_test.sh
  capability_test.sh
)

for name in "${tests[@]}"; do
  test_file="$ROOT/scripts/tests/$name"
  if DOTFILES_ROOT="$ROOT" bash "$test_file"; then
    printf '[PASS] %s\n' "$name"
  else
    printf '[FAIL] %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
done

printf '\nContract result: %d failure(s)\n' "$failures"
[ "$failures" -eq 0 ]
