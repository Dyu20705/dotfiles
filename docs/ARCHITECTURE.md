# Configuration Architecture

## Scope

This repository is a personal, Ubuntu-first and Zsh-first configuration. It is
not a multi-user dotfiles distribution, desktop rice, release product or
cross-platform compatibility project.

The primary runtime path is:

```text
WezTerm -> tmux -> Zsh -> project commands
                   |-> Neovim
                   |-> Git / LazyGit
```

Bash is retained only as the implementation runtime for bootstrap, diagnostics,
tests and maintenance scripts. No Bash interactive configuration is deployed.

## Sources of truth

- `config/workflow.json`: profiles, dependencies, performance budgets and links.
- Native component files: Zsh, tmux, Neovim, WezTerm, Git and LazyGit configs.
- `scripts/dot`: stable operator entrypoint over focused scripts.
- Local overlays outside Git: identity, secrets, private paths and assets.

## Directory map

| Path | Responsibility |
| --- | --- |
| `zsh/` | Interactive shell configuration and helper functions |
| `wezterm/` | Terminal entrypoint, appearance and optional media controls |
| `tmux/` | Sessions, panes, clipboard and terminal workflow |
| `nvim/` | Precision editing, navigation and diagnostics |
| `git/` | Canonical Git behavior without tracked personal identity |
| `lazygit/` | Optional TUI preferences layered over Git |
| `scripts/` | Install, doctor, backup, validation and workflow commands |
| `config/` | Machine-readable profiles and local-overlay examples |
| `capabilities/` | Optional personal extensions that stay outside the core path |
| `docs/` | Stable operator and maintenance documentation only |

## Profiles

- `minimal`: recovery commands and Git configuration; no managed interactive
  shell.
- `normal`: daily Zsh, tmux and Neovim workflow.
- `full`: normal plus WezTerm, LazyGit and optional helpers.

Profiles describe feature breadth. Contexts (`desktop`, `laptop`, `server`,
`remote`) describe the machine or session. Private overlays remain independent
from both.

## Private boundaries

The repository must never own:

- personal Git identity or signing material;
- access tokens, API keys or private keys;
- hostnames and private absolute paths;
- clipboard contents;
- local image/audio libraries;
- generated caches, history and runtime state.

Tracked example files contain placeholders. Populated values live under the
user's home/XDG directories and are loaded only at runtime.

## Change rule

A tracked addition must improve a repeated personal workflow, have a clear
owner, degrade quietly when optional dependencies are absent, and include a
removal path. Public roadmaps, release evidence and implementation-plan
archives do not belong in this repository.
