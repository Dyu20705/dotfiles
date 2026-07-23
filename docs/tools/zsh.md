# Zsh

## Purpose

Zsh is the default interactive shell for the repo. It provides the richer prompt and the optional productivity integrations.

## Why This Setup Exists

- keep the common shell fast and idempotent
- only load heavier integrations when they are available
- downgrade automatically in remote, CI, or nested tmux sessions

## Key Features Actually Enabled

| Feature | Behavior |
| --- | --- |
| Shell modes | `normal`, `minimal`, and `full` via `DOTFILES_SHELL_MODE` |
| Remote downgrade | SSH, CI, and nested tmux sessions can switch to minimal mode |
| PATH handling | Idempotent `PATH` mutation with duplicate protection |
| Prompt | `starship` when available, fallback prompt otherwise |
| Optional integrations | `zoxide`, `fzf`, `direnv`, `atuin` in full mode |
| Diagnostics | `check_tools` warning for missing core tools |

## Important Keybindings / Aliases

| Name | Meaning |
| --- | --- |
| `ga` / `gc` / `gp` | Git add, commit, push |
| `gl` / `gs` / `gd` | Git log, status, diff |
| `vi` / `vim` | Open Neovim |
| `reload` | Restart the shell |
| `sudo` | Preserve alias expansion after sudo |

## Typical Usage Flow

1. Start a local terminal session in normal mode.
2. Let Zsh load prompt and optional navigation tools when they exist.
3. Use minimal mode for remote, tmux, or CI-like shells.

## Productivity Tips

- keep optional tools optional; missing binaries should not break the shell
- use `reload` instead of reopening the terminal after editing the shell config
- prefer `zoxide` for navigation and `fzf` for interactive selection when they are installed

## Common Pitfalls

- assuming full integrations exist in remote shells
- adding duplicate PATH entries manually
- treating Zsh as a place for slow bootstrap logic

## Related Tools

- [Bash](bash.md)
- [tmux](tmux.md)
- [Shell aliases](shell-aliases.md)
