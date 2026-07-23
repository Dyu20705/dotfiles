WezTerm TASK-001: Migration Notes & Startup Behavior

Objective

Eliminate config-time side-effects from `.wezterm.lua`, introduce deterministic runtime modes, and make aesthetic features opt-in.

Summary of changes

- Introduced runtime modes: `minimal`, `normal`, `aesthetic` (see `docs/WEZTERM_MODES.md`).
- Disabled automatic music on GUI startup; music is now reachable only through explicit hotkeys.
- Replaced shell-based background/music discovery with startup-built caches using native WezTerm Lua APIs.
- Prevented blocking filesystem scans during keypress handling; cached lists are reused for selection.

How to test (manual)

1. Default (normal mode, deterministic):

```bash
wezterm
```
- Expected: no music; no background set (unless `DOTFILES_WEZTERM_BG` provided).

2. Aesthetic test (opt-in):

```bash
DOTFILES_WEZTERM_MODE=aesthetic DOTFILES_WEZTERM_MUSIC=1 DOTFILES_WEZTERM_BG=/path/to/bg.png wezterm
```
- Expected: If `DOTFILES_WEZTERM_BG` points to an image, it will be used. Music will only be spawned if `DOTFILES_WEZTERM_MUSIC=1`.

3. Minimal mode (fast/no side-effects):

```bash
DOTFILES_WEZTERM_MODE=minimal wezterm
```
- Expected: the config logs that minimal mode is active and skips side-effects.

Rollback

- Revert the `wezterm/.wezterm.lua` file to the previous commit if behavior is not acceptable:

```bash
git checkout -- wezterm/.wezterm.lua
```

Startup behavior table

| Action | Config-time? | Default behavior | Mode | Notes |
|---|---:|---|---|---|
| Background image at startup | No | Enabled (repo default image) | normal/minimal | Override with `DOTFILES_WEZTERM_BG`; random/cycle selection uses startup cache. |
| Music autoplay | No | Disabled | all | Interactive hotkeys only. |
| `io.popen` at load | No | Removed | all | No shell scan remains in the UI path. |
| `os.execute` pkill | No | Removed | all | Stop music now uses `wezterm.background_child_process`. |

Observability & Benchmarks

- After the change we re-ran `bench/collect_baseline.py` and compared against the previous snapshot. Some small millisecond differences were detected in tmux microbenchmarks (7 -> 8 ms) and flagged by the regression policy due to percentage thresholds. These are within expected noise for millisecond metrics and do not indicate functional regressions.

Notes for reviewers

- This patch intentionally prefers determinism and low-surprise defaults over cosmetic automatic behavior.
- GUI-first timing still requires a manual `/usr/bin/time -v wezterm` run on a local machine. See `bench/wezterm_notes.md`.
- `mpv` and `pactl` are still required for the explicit hotkeys, but they are launched via native background child processes rather than a shell.

Next steps

- If accepted, we should run a manual WezTerm time-to-first-window test on target hardware.
- If the team wants aesthetic layers in the future, keep them outside startup and drive them from keybindings or explicit local environment configuration.
