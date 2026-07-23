# Productivity Patterns

## Purpose

These are reusable patterns that show up across the repo. They are more useful than tool lists because they describe how the tools fit together.

## Patterns

| Pattern | Why it works here |
| --- | --- |
| One tmux session per project | Keeps windows, panes, and working directories predictable |
| One pane per concern | Editor, logs, tests, and shell commands stay separate |
| Review in layers | Gitsigns for hunks, Diffview for patches, LazyGit for repo overview |
| Cache expensive status | tmux status does not shell out repeatedly |
| Make shell mode explicit | Remote and nested shells skip optional integrations |
| Keep docs close to config | Markdown rendering makes the repo easier to read in Neovim |

## Daily Pattern

1. Open WezTerm and attach the project tmux session.
2. Split the session into edit, test, and inspect panes.
3. Use Neovim for the file you are changing.
4. Use Git or LazyGit to review the patch before committing.
5. Save the tmux session if the work should be resumed later.

## Incident Pattern

- keep one pane on logs
- keep one pane on commands that may block or retry
- keep one pane on the editor for notes and fixes
- use LazyDocker or SSH inside the existing session instead of starting a separate window tree

## Related Guides

- [Workflow overview](overview.md)
- [tmux workflow](tmux-workflow.md)
- [Neovim workflow](neovim-workflow.md)
- [Git workflow](git-workflow.md)
