# tmux Workflow

## Purpose

tmux is the center of the session model. It owns panes, windows, session switching, cached status, clipboard paste, and simple recovery.

## Why This Setup Exists

- make the session layout explicit
- avoid slow status bar work
- keep nested tmux usable
- preserve a predictable save/restore path

## Important Keys

| Key | Action |
| --- | --- |
| `Ctrl+A` | tmux prefix |
| `Ctrl+A` then `s` | Session chooser |
| `Ctrl+A` then `|` | Split horizontally |
| `Ctrl+A` then `-` | Split vertically |
| `Ctrl+A` then `c` | New window in the current path |
| `Ctrl+A` then `v` | Open Neovim in a split |
| `Ctrl+A` then `C-s` | Save session |
| `Ctrl+A` then `C-l` | Restore session |
| `Ctrl+A` then `r` | Reload tmux config |
| `Ctrl+A` then `C-v` | Paste clipboard content |
| `Ctrl+A` then `D` | Show tmux diagnostics |

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

- [Terminal workflow](terminal-workflow.md)
- [Productivity patterns](productivity-patterns.md)
- [tmux tool guide](../tools/tmux.md)
