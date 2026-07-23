# Terminal Workflow

## Purpose

This is the daily entrypoint workflow for the repo. WezTerm opens tmux, tmux manages the session, and the shell adapts based on context.

## Why This Setup Exists

- keep startup deterministic
- make remote and nested shells cheaper
- avoid mixing editor, shell, and session responsibilities

## Main Flow

| Step | Tool | What happens |
| --- | --- | --- |
| 1 | WezTerm | Starts tmux by default when tmux is present |
| 2 | tmux | Restores or creates a session, with cached status and chooser support |
| 3 | Shell | Loads a normal or minimal mode depending on SSH, TMUX, or CI context |
| 4 | Neovim | Handles editing, search, review, tests, and debug |
| 5 | Git/LazyDocker | Handles review or container inspection when needed |

## Important Entry Points

| Tool | Entry point |
| --- | --- |
| WezTerm | `wezterm/.wezterm.lua` |
| tmux | `tmux/tmux.conf` |
| Bash | `bash/.bash_profile` and `bash/.bashrc` |
| Zsh | `zsh/.zshrc` |

## Productivity Tips

- keep one tmux session per project or incident
- use one pane for editing, one for logs, and one for commands
- prefer the shell's minimal mode for SSH and nested tmux usage
- keep expensive tasks out of status bars and run them on demand

## Common Pitfalls

- opening extra shells when tmux is already available
- assuming full shell integrations exist in remote or nested sessions
- using the terminal emulator as the session manager instead of tmux

## Related Guides

- [tmux workflow](tmux-workflow.md)
- [Git workflow](git-workflow.md)
- [Neovim workflow](neovim-workflow.md)
- [Productivity patterns](productivity-patterns.md)
