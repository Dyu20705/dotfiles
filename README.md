# Dotfiles

Ubuntu-first terminal workstation built around WezTerm, tmux, Bash/Zsh,
Neovim and Git. The current v0 prioritizes a short usable path, rollback and
diagnostics; deeper redesign can replace internals behind the stable commands.

## Quick start

`jq` and Git are the only bootstrap prerequisites.

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles

# Inspect the Ubuntu transaction without changing the machine.
bash scripts/dot packages --profile normal --dry-run

# Install packages explicitly when ready, then deploy links.
bash scripts/dot packages --profile normal --yes
bash scripts/dot install --profile normal

# The command is now linked into ~/.local/bin.
dot doctor
dot check runtime
```

Create private Git identity after deployment:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

## Daily workflow

```bash
dot status
dev --list
dev my-project

gw new issue-123 main
gw status
gw open issue-123
```

`dev` discovers Git repositories beneath `DOTFILES_PROJECT_DIRS`, uses `fzf`
when available and otherwise accepts a refined query. It attaches to one stable
tmux session per canonical project path.

`gw` is a thin offline Git worktree guard. It refuses duplicate checked-out
branches and dirty removal unless `--force` is explicit. It never fetches,
deletes branches or merges.

## Profiles and contexts

Profiles control feature breadth:

- `minimal`: Bash, Git, operator command and recovery path;
- `normal`: daily Zsh, tmux and Neovim workflow;
- `full`: normal plus WezTerm, LazyGit and optional media/container helpers.

Contexts describe the machine: `desktop`, `laptop`, `server` and `remote`.
SSH, CI and headless sessions conservatively resolve to minimal mode unless
`DOTFILES_ALLOW_FULL_REMOTE=1` is explicit.

Inspect the effective non-secret state:

```bash
dot env
dot env --json | jq
```

## Backup, restore and uninstall

Every mutating bootstrap run records a manifest beneath
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups`.

```bash
dot backup list
dot backup restore <id>
dot uninstall --profile normal --dry-run
dot uninstall --profile normal
```

Restore refuses a path changed after deployment unless `--force` is supplied.
Uninstall removes only symlinks that still point into this checkout.

## tmux and Neovim

- tmux prefix: `Ctrl+A`;
- reload: `Ctrl+A`, then `r`;
- system clipboard paste: `Ctrl+A`, then `p`;
- `Ctrl+V` remains owned by applications;
- Neovim find namespace: `<leader>f`;
- Git namespace: `<leader>g`;
- diagnostics/lint namespace: `<leader>x`.

TPM is optional. Core tmux works without it:

```bash
bash scripts/install-tmux-plugins.sh --check
bash scripts/install-tmux-plugins.sh --install
```

Extended Neovim owners such as terminal, tests, DAP UI, file tree and broad Git
UI remain capability-gated rather than normal-startup dependencies.

## Capability packs and private overlays

Enable the read-only system inspection demonstration pack:

```bash
dot capability list
dot capability enable system
dot capability doctor system
dot capability disable system
```

Private values belong outside Git. Examples are provided for shell/context,
tmux, Neovim, WezTerm and Git identity. Minimal mode never loads capability
packs.

## Verification

```bash
dot check static
dot check runtime
dot check full
bash scripts/test-v0.sh
dot bench --json | jq
bash scripts/security-check.sh
```

CI runs Markdown, static contracts, Ubuntu/macOS runtime smoke tests, Ubuntu
clean-room deployment and security checks. GUI rendering, physical key routing,
Wayland/X11/OSC52 clipboard behavior, media playback and private assets require
manual workstation acceptance.

## LazyDocker fallback

Prefer a native LazyDocker release. The Compose helper is pinned and mounts the
Docker socket, which grants powerful host control:

```bash
docker compose run --rm lazydocker
```

Override `LAZYDOCKER_IMAGE` only after verifying an explicit tag or digest.

## Documentation

- [Cheat sheet](docs/CHEATSHEET.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Git and worktrees](docs/GIT_WORKFLOW.md)
- [Keymaps](docs/KEYMAPS.md)
- [Neovim plugin audit](docs/NEOVIM_PLUGINS.md)
- [Security](docs/SECURITY.md)
- [Benchmarks](docs/BENCHMARKS.md)
- [Testing](docs/TESTING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Release evidence](docs/RELEASE_EVIDENCE.md)
