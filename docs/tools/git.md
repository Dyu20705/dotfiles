# Git

## Purpose

Git is configured to behave the same way across machines and to support both CLI and interactive review.

## Why This Setup Exists

- predictable defaults reduce surprises in review and merge flows
- diagnostics expose editor, pager, and signing resolution
- aliases are intentionally simple so they work everywhere

## Key Features Actually Enabled

| Feature | Value |
| --- | --- |
| Default branch | `main` |
| Pager | `less -FRX` |
| Merge style | `zdiff3` |
| Diff algorithm | `histogram` |
| Aliases | `st`, `co`, `br`, `ci`, `ca`, `d`, `lg`, `last`, `unstage` |
| Editor | `nvim` |
| Diagnostics | `git/diagnostics.sh` |

## Important Keybindings / Aliases

| Alias | Expands to |
| --- | --- |
| `st` | `status` |
| `co` | `checkout` |
| `br` | `branch` |
| `ci` | `commit` |
| `ca` | `commit -a` |
| `d` | `diff` |
| `lg` | Graph log view |
| `last` | Last commit with stat |
| `unstage` | Reset staged changes |

## Typical Usage Flow

1. Check `git status` or `git diff` for a quick local view.
2. Open Neovim for Gitsigns, Diffview, or Neogit review.
3. Use LazyGit when the whole repository state matters.
4. Run `git/diagnostics.sh` if a machine resolves editor or pager differently.

## Productivity Tips

- keep aliases small and builtin-only
- use diagnostics before blaming the shell for editor or pager issues
- prefer `git log --graph --decorate --oneline --all` when you need full branch shape

## Common Pitfalls

- assuming `GIT_EDITOR` is always unset; external environments can override it
- using shell-out aliases that depend on optional tools
- forgetting that `less -FRX` is intentionally tuned for Git output

## Related Tools

- [LazyGit](lazygit.md)
- [Neovim](nvim.md)
- [Shell aliases](shell-aliases.md)
