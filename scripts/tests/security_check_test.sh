#!/usr/bin/env bash
set -euo pipefail

ROOT=${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scripts" "$tmp/.github/workflows"
cp "$ROOT/scripts/security-check.sh" "$tmp/scripts/security-check.sh"

git -C "$tmp" init -q
git -C "$tmp" config user.email test@example.invalid
git -C "$tmp" config user.name test
printf 'safe\n' > "$tmp/README.md"
git -C "$tmp" add .
git -C "$tmp" commit -qm baseline

DOTFILES_ROOT="$tmp" bash "$tmp/scripts/security-check.sh" >/dev/null

expect_rejected() {
  local value=$1
  printf 'TOKEN=%s\n' "$value" > "$tmp/fixture.txt"
  git -C "$tmp" add fixture.txt

  if DOTFILES_ROOT="$tmp" bash "$tmp/scripts/security-check.sh" >/dev/null 2>&1; then
    printf 'security scanner accepted token fixture\n' >&2
    return 1
  fi

  git -C "$tmp" reset -q --hard HEAD
}

openai_key='sk-'
openai_key+='proj-'
openai_key+=$(printf 'A%.0s' {1..48})
expect_rejected "$openai_key"

aws_key='AS'
aws_key+='IA'
aws_key+=$(printf 'A%.0s' {1..16})
expect_rejected "$aws_key"

printf 'PASS: security scanner fixtures\n'
