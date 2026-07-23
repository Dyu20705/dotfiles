# Bash

## Purpose

Bash is the compatibility shell. It keeps login setup, environment setup, and interactive behavior separate so non-interactive shells stay cheap.

## Why This Setup Exists

- login shells should only source the shared environment
- interactive shells should add aliases and completions
- remote and CI shells should avoid extra work when possible

## Key Features Actually Enabled

| Feature | File |
| --- | --- |
| Shared environment | `bash/.bash_env` |
| Login shell entry | `bash/.bash_profile` |
| Interactive shell runtime | `bash/.bashrc` |
| Login environment hook | `bash/.profile` |
| Interactive aliases | `bash/.bash_aliases` |
| Diagnostics | `dotfiles-shell-diagnostics` function |

## Important Keybindings / Aliases

| Name | Meaning |
| --- | --- |
| `..` / `...` | Move up one or two directories |
| `ll` / `la` / `l` | Listing shortcuts |
| `mkcd` | Create a directory and enter it |

## Typical Usage Flow

1. Login shell sources `.profile` and `.bash_env`.
2. Interactive shell sources aliases and optional completions.
3. Remote or tmux shells fall back to minimal mode when needed.

## Productivity Tips

- keep shared environment variables in `.bash_env`
- keep prompt or completion logic out of login-only files
- use `dotfiles-shell-diagnostics` when a machine behaves differently

## Common Pitfalls

- putting interactive logic in `.profile`
- editing PATH in multiple files without a single prepend helper
- assuming Bash aliases are available in minimal shells

## Related Tools

- [Zsh](zsh.md)
- [tmux](tmux.md)
- [Git](git.md)
- [Shell aliases](shell-aliases.md)
