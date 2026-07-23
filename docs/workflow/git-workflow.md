# Git Workflow

## Purpose

The repo supports both CLI Git and interactive review. The goal is to make inspection, staging, and commit creation fast without making the workflow opaque.

## Why This Setup Exists

- keep Git defaults deterministic across machines
- provide both file-level and patch-level review
- avoid heavyweight auto-fetch or auto-refresh behavior in the TUI

## Key Tools

| Tool | Role |
| --- | --- |
| `git` | Core version control and diagnostics |
| `gitsigns` | Hunk navigation, blame, and inline diffing in Neovim |
| `diffview` | Full patch review and file history |
| `neogit` | Interactive staging and commit flow |
| `lazygit` | Repo-wide TUI review and branch management |
| `telescope` | Search files, buffers, and history while reviewing changes |

## Typical Review Flow

1. Open the branch in Neovim.
2. Use `Gitsigns` to inspect hunks and blame.
3. Open `Diffview` for the full patch or file history.
4. Use `Neogit` or LazyGit for staging and commits.
5. Use Telescope to jump to affected files or search strings.

## Important Commands

| Command | Purpose |
| --- | --- |
| `git diff` | Review the current patch |
| `git log --graph --decorate --oneline --all` | Inspect branch history |
| `:Neogit` | Open the interactive Git UI in Neovim |
| `:DiffviewOpen` | Open a full diff view |
| `:DiffviewFileHistory` | Inspect file history |
| `./git/diagnostics.sh all` | Inspect editor, pager, and signing state |

## Productivity Tips

- use `git diff` for quick checks and Diffview for larger changes
- keep `autoFetch` and `autoRefresh` off in LazyGit when you want local-only review
- use `git/diagnostics.sh` when a machine behaves differently from the others

## Common Pitfalls

- assuming LazyGit will refresh on its own
- forgetting that the Git pager is intentionally set to `less -FRX`
- mixing review and commit responsibilities in one pane when a second pane would be clearer

## Related Guides

- [Neovim workflow](neovim-workflow.md)
- [tmux workflow](tmux-workflow.md)
- [Git tool guide](../tools/git.md)
- [LazyGit tool guide](../tools/lazygit.md)
