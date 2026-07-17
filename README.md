# Dotfiles

[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-111827?style=flat-square)](https://github.com/Dyu20705/dotfiles)
[![Shell](https://img.shields.io/badge/shell-zsh%20%2B%20bash-2a2a2a?style=flat-square)](https://github.com/Dyu20705/dotfiles)
[![Editor](https://img.shields.io/badge/editor-Neovim-57a143?style=flat-square)](https://github.com/Dyu20705/dotfiles)
[![Terminal](https://img.shields.io/badge/terminal-WezTerm%20%2B%20tmux-0f172a?style=flat-square)](https://github.com/Dyu20705/dotfiles)

Terminal-first dotfiles built around a predictable WezTerm → tmux → shell →
Neovim workflow. Native configuration formats stay native; Bash and `jq` provide
installation, diagnostics, state management and smoke tests.

## Design principles

- tmux is a local session layer, not a signal to disable shell features.
- Optional tools degrade quietly when unavailable.
- Cache, state and personal identity stay outside the repository.
- One canonical config exists per application.
- Runtime smoke tests complement syntax linting.
- Machine-specific changes belong in local files or environment variables.

## Stack

| Layer | Role | Canonical config |
| --- | --- | --- |
| Terminal | WezTerm entrypoint and optional aesthetics | `wezterm/.wezterm.lua` |
| Sessions | panes, windows, clipboard and explicit persistence | `tmux/tmux.conf` |
| Shell | local/remote-aware Bash and Zsh startup | `bash/`, `zsh/.zshrc` |
| Editor | Neovim 0.11.3+ with lazy-loaded plugins | `nvim/.config/nvim/` |
| Git | portable defaults plus local identity | `git/.gitconfig` |
| TUI | LazyGit with a portable opener | `lazygit/config.yml` |
| Containers | optional pinned LazyDocker helper | `docker-compose.yaml` |

The supported commands, minimum versions, profiles and symlinks are declared in
`config/workflow.json`.

## Installation

`jq` is required by the manifest-driven tooling.

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles

bash scripts/bootstrap.sh --profile normal --dry-run
bash scripts/bootstrap.sh --profile normal
```

Profiles:

- `minimal`: Bash and Git baseline.
- `normal`: daily Zsh, tmux, Neovim and Git workflow.
- `full`: normal profile plus WezTerm and LazyGit.

Existing deployment targets are moved to
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups` before a new symlink is
created.

Create machine-local Git identity after bootstrapping:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

## Diagnostics and tests

```bash
bash scripts/doctor.sh --profile normal
bash scripts/doctor.sh --profile normal --json | jq

bash scripts/test.sh --profile static
bash scripts/test.sh --profile runtime
bash scripts/test.sh --profile full
```

Runtime tests use isolated temporary homes and a dedicated tmux socket. Missing
optional GUI applications are reported as skipped rather than silently assumed
to work.

## Runtime modes

### Shell

`DOTFILES_SHELL_MODE` accepts `minimal`, `normal` or `full`. SSH and CI sessions
fall back to minimal mode unless full mode is explicitly requested. A shell
inside tmux remains normal because tmux is the primary local workflow.

### WezTerm

`DOTFILES_WEZTERM_MODE` accepts:

- `minimal`: terminal and tmux only.
- `normal`: safe default with no media or background integrations.
- `aesthetic`: opt-in local backgrounds and music controls.

Aesthetic mode requires `DOTFILES_ROOT` so local assets can be found. Optional
asset paths can be overridden with `DOTFILES_WEZTERM_BG_DIR`,
`DOTFILES_WEZTERM_MUSIC_DIR` and `DOTFILES_WEZTERM_BG`.

## Core keymaps

### tmux

- Prefix: `Ctrl+A`
- Split horizontal: `Prefix+\\`
- Split vertical: `Prefix+-`
- Session chooser: `Prefix+s`
- Clipboard paste: `Prefix+p` or `Shift+Insert`
- Reload: `Prefix+r`
- Diagnostics: `Prefix+D`

`Ctrl+V` is intentionally left to Neovim and other applications.

### Neovim namespaces

- `<leader>f`: find/Telescope
- `<leader>g`: Git
- `<leader>t`: tests
- `<leader>o`: terminal/open tools
- `<leader>d`: debugger
- `<leader>x`: diagnostics and lint

## tmux state and status

- Cached UI data: `${XDG_CACHE_HOME:-~/.cache}/dotfiles/tmux`
- Session metadata: `${XDG_STATE_HOME:-~/.local/state}/dotfiles/tmux/sessions`

Session metadata is written atomically as JSON through `jq`:

```bash
bash tmux/session-manager.sh create project "$PWD" "Current project"
bash tmux/session-manager.sh list
bash tmux/session-manager.sh restore
```

Weather and random-note status collectors are disabled by default. Enable them
explicitly with `DOTFILES_STATUS_WEATHER=1` or
`DOTFILES_STATUS_RANDOM_NOTE=1`.

## LazyDocker helper

```bash
docker compose run --rm lazydocker
```

The image defaults to `v0.25.2`; override it with `LAZYDOCKER_VERSION` after
reviewing the release. Mounting `/var/run/docker.sock` gives the container
powerful control over the host Docker daemon. Only run trusted images.

## Documentation

- [Dependencies](docs/DEPENDENCIES.md)
- [Testing](docs/TESTING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Contributing

- Keep changes tied to a real workflow problem.
- Prefer small native configs and explicit shell helpers.
- Update `config/workflow.json` when requirements or deployment paths change.
- Run `bash scripts/test.sh --profile full` before opening a pull request.
