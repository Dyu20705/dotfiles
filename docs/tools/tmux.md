# tmux

## Purpose

tmux is the session and pane manager for the whole stack.

## Why This Setup Exists

- keep sessions deterministic and easy to reattach
- make pane navigation feel like Vim
- avoid status bar shell-outs by caching expensive values

## Key Features Actually Enabled

| Feature | Value |
| --- | --- |
| Prefix | `Ctrl+A` |
| Split panes | Current working directory is preserved |
| Session chooser | `prefix + s` |
| Save / restore | Manual resurrect bindings |
| Clipboard paste | Explicit binding via helper script |
| Nested helper | Prefix forwarding when tmux is nested |
| Status bar | Cached session and status text |

## Important Keybindings / Aliases

| Key | Action |
| --- | --- |
| `Ctrl+A` then `|` | Split horizontally |
| `Ctrl+A` then `-` | Split vertically |
| `Ctrl+A` then `c` | New window |
| `Ctrl+A` then `v` | Open Neovim in a split |
| `Ctrl+A` then `s` | Choose session |
| `Ctrl+A` then `C-s` | Save session |
| `Ctrl+A` then `C-l` | Restore session |
| `Ctrl+A` then `r` | Reload tmux config |
| `Ctrl+A` then `C-v` | Paste clipboard |
| `Ctrl+A` then `D` | Show diagnostics |

## Session Model

| Script | Role |
| --- | --- |
| `tmux/sessions_cache.sh` | Builds the cached session list for status-left |
| `tmux/update_cached_status.sh` | Loads cached status text into tmux options |
| `tmux/session-manager.sh` | Session lifecycle helpers |
| `tmux/diagnostics.sh` | Startup, nesting, checksum, and status checks |

## Typical Flow

1. Open WezTerm.
2. Select or create a tmux session.
3. Split panes for editor, logs, and commands.
4. Save the session before switching tasks.
5. Reload the config rather than restarting the terminal when you change tmux.

## Productivity Tips

- keep one session per project or incident
- let the cached status scripts run instead of embedding shell commands directly in status text
- use the nested prefix-forward helper instead of manually wrestling with outer tmux

## Common Pitfalls

- expecting tmux-resurrect to auto-save without pressing the save binding
- putting slow commands into status-left or status-right
- forgetting that reload and restore are separate actions

## Related Guides

- [Terminal workflow](../workflow/terminal-workflow.md)
- [Productivity patterns](../workflow/productivity-patterns.md)
- [WezTerm](wezterm.md)
