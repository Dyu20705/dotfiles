# LazyGit

## Purpose

LazyGit is the interactive Git TUI for repository-wide review, staging, and commit work.

## Why This Setup Exists

- give Git a fast visual layer without replacing CLI Git
- keep refresh behavior explicit instead of automatic
- use Neovim as the editor when editing commits or files

## Key Features Actually Enabled

| Feature | Value |
| --- | --- |
| File tree | Enabled |
| Command log | Enabled |
| Root item | Visible in file tree |
| Auto fetch | Disabled |
| Auto refresh | Disabled |
| Top-level branches | `main` and `master` |
| Commit wrapping | 72 columns |
| Editor | `nvim` |

## Important Keybindings / Aliases

LazyGit mostly uses its built-in keys. Useful defaults to remember:

| Key | Meaning |
| --- | --- |
| `q` | Quit |
| `?` | Show key help |
| `enter` | Open or inspect the selected item |
| `space` | Mark changes |
| `s` | Stage |
| `u` | Unstage |
| `c` | Commit |

## Typical Usage Flow

1. Open LazyGit when you want a repository overview.
2. Stage or unstage changes in the tree or diff view.
3. Open files in Neovim when you need richer editing.
4. Commit once the patch is understood.

## Productivity Tips

- keep LazyGit for review and staging, not for hidden automation
- use `nvim` as the file editor when you jump out of the TUI
- rely on topological log ordering when inspecting branch history

## Common Pitfalls

- expecting refreshes to happen automatically
- leaving the TUI open as a substitute for commit discipline
- forgetting that the config intentionally prefers explicit action over background sync

## Related Tools

- [Git](git.md)
- [Neovim](nvim.md)
- [tmux](tmux.md)
