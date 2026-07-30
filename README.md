# Dotfiles

[![validate][validate-badge]][validate-workflow]

[validate-badge]: https://github.com/Dyu20705/dotfiles/actions/workflows/validate.yml/badge.svg?branch=main
[validate-workflow]: https://github.com/Dyu20705/dotfiles/actions/workflows/validate.yml

Personal, Ubuntu-first terminal configuration built around **WezTerm → tmux → Zsh**,
with Neovim, Git and optional LazyGit.

This repository is maintained for one user's machines. External contributions are
not accepted; fork it and adapt it to your own environment.

## Quick start

Prerequisites: Git, Bash and `jq`. Bash is used to run the management scripts;
the deployed interactive shell is Zsh.

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles

# Inspect package changes first.
bash scripts/dot packages --profile normal --dry-run

# Install packages and deploy the normal Zsh/tmux/Neovim profile.
bash scripts/dot packages --profile normal --yes
bash scripts/dot install --profile normal

dot doctor
exec zsh
```

Create the untracked Git identity file after deployment:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

## Overview

| Area | Role |
| --- | --- |
| WezTerm | Terminal entrypoint and optional local media/background controls |
| tmux | Persistent sessions, panes and clipboard bridge |
| Zsh | Primary and only managed interactive shell |
| Neovim | Precision editor, navigation, diagnostics and focused refactoring |
| Git | Canonical CLI and configuration source of truth |
| LazyGit | Optional TUI that executes Git operations; it does not replace Git |
| `dot` | Install, diagnose, validate, back up, restore and uninstall |
| `dev` / `gw` | Project sessionizer and guarded Git worktree helpers |

Private identity, paths, host-specific settings and assets stay outside Git in
local overlays.

## Documentation

- [Complete cheat sheet](docs/CHEATSHEET.md)
- [Configuration architecture](docs/ARCHITECTURE.md)
- [Maintenance and validation](docs/MAINTENANCE.md)
- [Security model](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
