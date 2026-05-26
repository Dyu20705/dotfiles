#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

print_config_layering() {
    echo "=== GIT CONFIG LAYERING ==="
    git -C "$ROOT" config --show-origin --list
}

print_editor_resolution() {
    echo "=== GIT EDITOR RESOLUTION ==="
    echo "GIT_EDITOR=${GIT_EDITOR:-<unset>}"
    echo "core.editor=$(git -C "$ROOT" config --get core.editor 2>/dev/null || echo '<unset>')"
    echo "git var GIT_EDITOR=$(git -C "$ROOT" var GIT_EDITOR 2>/dev/null || echo '<unresolved>')"
    echo "nvim=$(command -v nvim 2>/dev/null || echo '<missing>')"
}

print_pager_resolution() {
    echo "=== GIT PAGER RESOLUTION ==="
    echo "core.pager=$(git -C "$ROOT" config --get core.pager 2>/dev/null || echo '<unset>')"
    echo "GIT_PAGER=${GIT_PAGER:-<unset>}"
    echo "LESS=${LESS:-<unset>}"
}

print_signing_state() {
    echo "=== GIT SIGNING STATE ==="
    echo "gpg.format=$(git -C "$ROOT" config --get gpg.format 2>/dev/null || echo '<unset>')"
    echo "commit.gpgsign=$(git -C "$ROOT" config --get commit.gpgsign 2>/dev/null || echo '<unset>')"
    echo "user.signingkey=$(git -C "$ROOT" config --get user.signingkey 2>/dev/null || echo '<unset>')"
    echo "gpg.ssh.program=$(git -C "$ROOT" config --get gpg.ssh.program 2>/dev/null || echo '<unset>')"
    echo "ssh-keygen=$(command -v ssh-keygen 2>/dev/null || echo '<missing>')"
    echo "gpg=$(command -v gpg 2>/dev/null || echo '<missing>')"
}

case "${1:-all}" in
    config)
        print_config_layering
        ;;
    editor)
        print_editor_resolution
        ;;
    pager)
        print_pager_resolution
        ;;
    signing)
        print_signing_state
        ;;
    all)
        print_config_layering
        echo
        print_editor_resolution
        echo
        print_pager_resolution
        echo
        print_signing_state
        ;;
    *)
        echo "Usage: $0 [config|editor|pager|signing|all]" >&2
        exit 1
        ;;
esac