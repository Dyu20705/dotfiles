# tmux Runtime Hardening — Observability & Nested/SSH Reliability

Summary
- Added a lightweight `observability.conf` to expose runtime metadata and small helpers.
- Sourced `observability.conf` from the canonical `tmux.conf`.
- Extended `tmux/diagnostics.sh` to report observability options and SSH/nested states.
- Conservative nested helper: `Prefix+P` forwards the prefix to an outer session (only bound when a nested environment is detected).
- When `SSH_CONNECTION` is present we set `set-clipboard` off (avoid relying on local GUI clipboards).

Runtime reasoning (before changes)
- Avoid polling: all diagnostics are computed at load-time or on-demand via a `Prefix+D` binding.
- Avoid hot-path shell-outs: added background `run-shell -b` tasks at config load only.
- Prefer tmux-native options and formats; observability values are stored in `@` options so they can be inspected with `tmux show-options`.

What changed (narrow, reversible patches)
- [tmux/tmux.conf](tmux/tmux.conf#L1-L40) now sources `observability.conf`.
- [tmux/observability.conf](tmux/observability.conf) added (sets `@tmux_*` options, nested detection, SSH handling, `Prefix+P` and `Prefix+D` bindings).
- [tmux/diagnostics.sh](tmux/diagnostics.sh) updated to report the new options.

What was verified automatically
- Repo scan for tmux files (configs and scripts).
- `diagnostics.sh` still retains startup measurement flows.

Manual validation still required
- Test with isolated tmux sockets: create a socket with `-L` and ensure `@tmux_active_socket` is populated.
- Test nested tmux manually: attach a client inside another tmux and press `Prefix+P` to forward prefix.
- SSH scenarios: open a remote SSH session to a host without GUI clipboard tools and verify `set-clipboard` stays off and clipboard commands don't block.
- Verify no material regression in startup time using `tmux/diagnostics.sh startup`.

Remaining technical debt / next steps
 - Improve robust nested-level detection across server vs client lifecycle (previously used a simple `$TMUX` check). We now compute a best-effort nesting depth and store it in `@tmux_nested_level` and also compute a `@tmux_config_hash` for config provenance.
- Audit `ui.conf` and status-right for any remaining shell-outs and convert them to tmux formats where possible.
- Add automated tests for nested detection using isolated sockets (requires careful server/client env setup).
- Document Linux/GNU-specific assumptions within `docs/` if deeper portability work is requested.
 - New quick diagnostics: run `./tmux/diagnostics.sh checksum` to print the active config checksum, and `./tmux/diagnostics.sh audit` to search `tmux/*.conf` for `#(` shell-out occurrences.

Audit summary (shell-out `#(...)` findings)
- I scanned the workspace for `#(...)` occurrences. Active configs under `tmux/*.conf` are free of hot-path shell-outs; occurrences were found in backup files and documentation. Specifically:
	- `tmux/.tmux.conf.backup`: several status `#(...)` shell-outs (pomodoro, random_note, memory/free calls).
	- `tmux/.tmux.conf.hardened`: a shell-out reading `~/.cache/tmux_status` (safe if cached externally).
	- Docs and notes contain examples in `docs/task3.md`.

Recommendations
- Replace per-redraw `#(...)` commands with a cached-value pattern:
	1) Aggregate heavy computations into a single cache file using `tmux/build_status_cache.sh`.
	2) Populate a tmux `@` option from the cache via an external updater or a load-time `run-shell -b` and use `#{@tmux_cached_status}` in your statusline.
 3) Prefer `tmux` formats and `#{...}` expressions for lightweight, per-redraw data.

CI Linting
- Add `./tmux/diagnostics.sh audit` as a non-blocking CI lint step to flag any reintroduced `#(...)` shell-outs in hot paths. Report as warnings (do not fail builds for optional tooling).

If you want, I can run the diagnostics script now (it will invoke `tmux`), or create a small test harness to programmatically exercise isolated sockets.

Automated helpers added
- `tmux/test_harness.sh`: safe, DRY-RUN first; run with `RUN=1` to execute isolated socket lifecycle and print `@tmux_*` observability options.
- `tmux/check_failure_modes.sh`: non-destructive checks for missing clipboard tools, TPM/plugins, resurrect files, and session collisions.

Usage examples:
```bash
# Dry-run harness (does nothing):
./tmux/test_harness.sh

# Execute the harness (will start a temporary tmux server on socket 'dotfiles_test'):
RUN=1 ./tmux/test_harness.sh

# Run failure-mode checks (read-only):
./tmux/check_failure_modes.sh
```

The above scripts are conservative: they avoid mutating your main tmux server and only create short-lived isolated servers when explicitly enabled.
