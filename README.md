# Dotfiles

[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-111827?style=flat-square)](https://github.com/Dyu20705/dotfiles)
[![Shell](https://img.shields.io/badge/shell-zsh%20%2B%20bash-2a2a2a?style=flat-square)](https://github.com/Dyu20705/dotfiles)
[![Editor](https://img.shields.io/badge/editor-Neovim-57a143?style=flat-square)](https://github.com/Dyu20705/dotfiles)
[![Terminal](https://img.shields.io/badge/terminal-WezTerm%20%2B%20tmux-0f172a?style=flat-square)](https://github.com/Dyu20705/dotfiles)

Terminal-first dotfiles for developers who spend most of the day in a shell, tmux, and Neovim. The setup favors predictable startup, low-noise defaults, and a workflow that stays fast on Linux and macOS.

## Overview

This repository configures a small, coherent stack rather than a pile of unrelated tools. WezTerm is the entrypoint, tmux owns sessions and panes, the shell stays mode-aware, and Neovim handles editing, review, tests, and debugging.

It is a good fit if you want:

- a tmux-first terminal workflow
- a Neovim setup that favors lazy loading and explicit keymaps
- deterministic Git defaults with both CLI and TUI review paths
- light Docker workflow support through LazyDocker

## Stack Overview

| Layer | Role | Primary files |
| --- | --- | --- |
| Terminal | WezTerm entrypoint, background/media helpers | [wezterm/.wezterm.lua](wezterm/.wezterm.lua) |
| Session layer | Pane, window, and session orchestration | [tmux/tmux.conf](tmux/tmux.conf) |
| Shell | Mode-aware Zsh and Bash startup | [zsh/.zshrc](zsh/.zshrc), [bash/.bashrc](bash/.bashrc) |
| Editor | Neovim with lazy-loaded plugin modules | [nvim/.config/nvim/init.lua](nvim/.config/nvim/init.lua) |
| Git | Deterministic Git defaults and review helpers | [git/.gitconfig](git/.gitconfig), [lazygit/config.yml](lazygit/config.yml) |
| Containers | LazyDocker via Compose | [docker-compose.yaml](docker-compose.yaml) |

## Core Workflow

1. Open WezTerm. It starts tmux automatically when tmux is available.
2. Attach or create a session with tmux's session chooser.
3. Split panes for editor, logs, tests, and shell commands.
4. Open Neovim for edits, search, Git review, and test runs.
5. Use Git or LazyGit for staging and commits, then validate before push.

## Repository Structure

```text
.
├── bash/
├── docker-compose.yaml
├── git/
├── lazygit/
├── nvim/
├── tmux/
├── wezterm/
└── zsh/
```

## Installation

The repo does not ship a bootstrap script. Clone it somewhere stable, then symlink the configs you want to use.

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/dotfiles

ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/bash/.bashrc ~/.bashrc
ln -sf ~/dotfiles/bash/.bash_profile ~/.bash_profile
ln -sf ~/dotfiles/bash/.bash_env ~/.bash_env
ln -sf ~/dotfiles/bash/.bash_aliases ~/.bash_aliases
ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
mkdir -p ~/.config/lazygit ~/.config/nvim
ln -sf ~/dotfiles/lazygit/config.yml ~/.config/lazygit/config.yml
ln -sf ~/dotfiles/nvim/.config/nvim ~/.config/nvim
```

If you use Bash from a different checkout path, set `DOTFILES_ROOT` so the Bash wrappers can find the repo.

## Tooling Highlights

| Area | Highlights |
| --- | --- |
| tmux | `Ctrl+A` prefix, session chooser, cached status, save/restore bindings, nested prefix forwarding |
| Neovim | `Telescope`, `Gitsigns`, `Neogit`, `Diffview`, `Flash`, `Neotest`, `DAP`, `ToggleTerm`, `render-markdown` |
| Git | `histogram` diff, `zdiff3` merges, deterministic pager/editor defaults, simple aliases |
| Shell | Remote-aware shell mode, idempotent PATH handling, small alias set, optional prompt tooling |
| WezTerm | tmux-first startup, optional background/media behavior, tmux prefix forwarding keys |
| Docker | `docker-compose.yaml` service for LazyDocker with the Docker socket mounted |

## Contributing

- Keep changes tied to actual config and commands.
- Prefer small, atomic commits.
- Run `git diff --check` before pushing.
- Keep local docs, benchmarks, and generated assets out of commits unless they are intentionally part of the repo.

## Validation

Useful local checks:

```bash
git status
git diff --check
```

CI runs markdown, shell, YAML, and Lua validation so changes stay reproducible.
