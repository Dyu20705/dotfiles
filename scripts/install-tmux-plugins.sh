#!/usr/bin/env bash
set -euo pipefail
TPM_DIR="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}/tpm"
usage() { cat <<'EOF'
Usage: install-tmux-plugins.sh --check|--install|--update
EOF
}
case "${1:-}" in
  -h|--help) usage ;;
  --check)
    if [ -x "$TPM_DIR/tpm" ]; then printf 'TPM installed: %s\n' "$TPM_DIR"; exit 0; fi
    printf 'TPM not installed; core tmux remains available\n' >&2; exit 10
    ;;
  --install)
    command -v git >/dev/null 2>&1 || exit 30
    if [ ! -d "$TPM_DIR/.git" ]; then mkdir -p "$(dirname "$TPM_DIR")"; git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"; fi
    "$TPM_DIR/bin/install_plugins"
    ;;
  --update)
    [ -d "$TPM_DIR/.git" ] || exit 10
    git -C "$TPM_DIR" pull --ff-only
    "$TPM_DIR/bin/update_plugins" all
    ;;
  *) usage >&2; exit 20 ;;
esac
