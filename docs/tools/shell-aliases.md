# Shell Aliases

## Purpose

This page groups the small shell convenience layer that exists across Bash and Zsh.

## Why This Setup Exists

- keep the convenience layer tiny and predictable
- use aliases for the common cases only
- avoid making the shell depend on optional tools for basic navigation

## Important Aliases and Functions

| Shell | Name | Meaning |
| --- | --- | --- |
| Bash and Zsh | `..` | `cd ..` |
| Bash and Zsh | `...` | `cd ../..` |
| Bash and Zsh | `mkcd` | Create a directory and enter it |
| Zsh | `vi` / `vim` | Open Neovim |
| Zsh | `ga`, `gc`, `gp` | Git add, commit, push |
| Zsh | `gl`, `gs`, `gd` | Git log, status, diff |
| Zsh | `reload` | Restart the shell |
| Zsh | `sudo` | Preserve alias expansion after sudo |
| Zsh | `ls`, `la`, `ll` | Use `exa` when available, fallback otherwise |
| Bash | `ll`, `la`, `l` | List shortcuts |

## Typical Usage Flow

1. Use the alias for the common path or Git operation.
2. Fall back to the underlying command when you need more control.
3. Keep optional shell integrations out of the way when the environment is remote or minimal.

## Productivity Tips

- use aliases for muscle memory, not for hiding complex behavior
- keep `mkcd` for throwaway directories and scratch work
- if an alias is not obvious, prefer the underlying command in documentation

## Common Pitfalls

- adding overlapping aliases in multiple shell files
- relying on Zsh-only helpers from Bash
- making aliases do too much work for basic shell tasks

## Related Tools

- [Bash](bash.md)
- [Zsh](zsh.md)
- [Git](git.md)
