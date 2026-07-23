WezTerm Runtime Modes

Purpose

Define deterministic runtime modes for WezTerm to separate startup-critical behavior from optional aesthetic side-effects.

Modes

- `minimal` — lowest latency; no visual or audio side-effects. Intended for remote, headless, battery-constrained, or focused work.
- `normal` — default mode; no automatic aesthetics. Interactive, opt-in behaviors are available via keybindings.
- `aesthetic` — explicit opt-in mode; reserved for future non-startup visual layers.

Environment variables

- `DOTFILES_WEZTERM_MODE` — sets the runtime mode. Valid values: `minimal`, `normal`, `aesthetic`. Defaults to `normal`.
- `DOTFILES_WEZTERM_BG` — path to a background image override. When unset, the repo default background image is used.

Operational rules

- No shell-outs or blocking IO occur during module load.
- Background and music file discovery are cached once at startup using native WezTerm Lua APIs.
- Background image selection is deterministic at startup and defaults to the repo image unless overridden by `DOTFILES_WEZTERM_BG`.
- Random/cycle background selection reuses the startup cache; no filesystem scan happens during keypress handling.
- Music playback is interactive-only through hotkeys; startup music is disabled.
- Any external process spawn happens only from explicit hotkeys.
- Default mode for development work is `normal` (deterministic, no surprises).

Examples

- Start in minimal mode (no side-effects):

```bash
DOTFILES_WEZTERM_MODE=minimal wezterm
```

- Start with aesthetic mode (reserved for future non-startup visuals):

```bash
DOTFILES_WEZTERM_MODE=aesthetic wezterm
```

Rollback

- To revert to previous behavior, restore the previous `wezterm/.wezterm.lua` from Git history.
- This patch is reversible and isolated to the `wezterm/` folder.
