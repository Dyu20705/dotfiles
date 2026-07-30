# shellcheck shell=sh
# Read-only system capability helpers.
sysports() { if command -v ss >/dev/null 2>&1; then ss -lntup; elif command -v netstat >/dev/null 2>&1; then netstat -lntup; else return 10; fi; }
sysdisk() { df -hT; }
sysjournal() { command -v journalctl >/dev/null 2>&1 || return 10; journalctl --no-pager -n "${1:-100}"; }
