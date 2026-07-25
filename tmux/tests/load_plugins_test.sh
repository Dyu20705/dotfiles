#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LOADER="$ROOT/load_plugins.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# Missing TPM must degrade silently and successfully.
missing_home="$TMP/missing-home"
mkdir -p "$missing_home"
output=$(HOME="$missing_home" bash "$LOADER" 2>&1) || fail "missing TPM returned non-zero"
[ -z "$output" ] || fail "missing TPM emitted startup noise: $output"

# Installed TPM must be executed.
installed_home="$TMP/installed-home"
tpm_dir="$installed_home/.tmux/plugins/tpm"
mkdir -p "$tpm_dir"
marker="$TMP/tpm-ran"
cat > "$tpm_dir/tpm" <<EOF_TPM
#!/usr/bin/env bash
printf 'ran' > "$marker"
EOF_TPM
chmod +x "$tpm_dir/tpm"
HOME="$installed_home" bash "$LOADER"
[ "$(cat "$marker" 2>/dev/null)" = "ran" ] || fail "installed TPM was not executed"

printf 'PASS: load_plugins.sh\n'
