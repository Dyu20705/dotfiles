# Workflow Overview

This repo is organized around one idea: reduce context switching by making the terminal, session manager, shell, editor, and Git tools act like one workflow.

## Workflow Map

```text
WezTerm
  -> tmux session
    -> shell mode
      -> Neovim / Git / LazyGit / LazyDocker
```

| Workflow | Primary tools | Best starting point |
| --- | --- | --- |
| Daily development | WezTerm, tmux, Neovim, Git | [terminal-workflow.md](terminal-workflow.md) |
| Git review | Gitsigns, Diffview, Neogit, LazyGit, Telescope | [git-workflow.md](git-workflow.md) |
| Incident / infra | tmux, shell tools, LazyDocker, SSH | [terminal-workflow.md](terminal-workflow.md) |
| Documentation | Neovim, render-markdown, Markdown files | [neovim-workflow.md](neovim-workflow.md) |
| Multi-project | tmux sessions, panes, worktrees | [productivity-patterns.md](productivity-patterns.md) |

## What This Stack Optimizes

- deterministic session startup
- explicit pane and window layout
- a small number of high-value keybindings
- Git review at both file and patch level
- Markdown and config editing without leaving the terminal

## Read First

1. [Terminal workflow](terminal-workflow.md)
2. [tmux workflow](tmux-workflow.md)
3. [Neovim workflow](neovim-workflow.md)
4. [Git workflow](git-workflow.md)
5. [Docker workflow](docker-workflow.md)

## Signals To Watch

If a workflow feels slow, inspect the layer below it first:

- terminal startup: WezTerm or shell mode
- pane/session behavior: tmux
- search/edit lag: Neovim plugins or LSP
- Git UI lag: LazyGit refresh settings or network activity
