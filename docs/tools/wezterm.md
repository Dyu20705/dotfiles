# WezTerm

## Purpose

WezTerm is the terminal entrypoint and UI layer. In this repo it mainly launches tmux and provides a small amount of optional visual behavior.

## Why This Setup Exists

- make terminal startup tmux-first
- keep visuals optional instead of mandatory
- support small media and background features without adding another launcher

## Key Features Actually Enabled

| Feature | Value |
| --- | --- |
| Default program | `tmux new-session -A -s main` when tmux is available |
| Fallback | Login shell when tmux is missing |
| Background image | Optional local image support |
| Background music | Optional `mpv` playback |
| tmux prefix forwarding | `Alt+h/j/k/l` send tmux prefix keys |
| Link opening | `Ctrl+Shift+L` |
| Brightness control | `Ctrl+Shift+<` and `Ctrl+Shift+>` |

## Important Keybindings / Aliases

| Key | Action |
| --- | --- |
| `Alt+h/j/k/l` | Forward tmux navigation keys |
| `Ctrl+Shift+B` | Random background image |
| `Ctrl+Shift+<` / `Ctrl+Shift+>` | Adjust background brightness |
| `F6` | Play random music |
| `F7` | Stop music |
| `F8` / `F9` | Volume up / down |
| `F10` | Play the default music file |

## Typical Usage Flow

1. Open WezTerm.
2. Let it attach to the default tmux session.
3. Use the tmux prefix for session and pane work.
4. Use the optional media/background keys only when you want them.

## Productivity Tips

- treat the terminal as a launch surface, not the session manager
- keep background media optional so startup remains cheap
- use the tmux prefix forwarding keys when you want Vim-like pane movement from the terminal itself

## Common Pitfalls

- assuming the visual extras are always active
- forgetting that tmux is the first-class session layer
- depending on local media files that may not exist on every machine

## Related Tools

- [tmux](tmux.md)
- [Terminal workflow](../workflow/terminal-workflow.md)
