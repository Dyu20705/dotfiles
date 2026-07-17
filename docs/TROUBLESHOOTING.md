# Troubleshooting

## Start with diagnostics

```bash
bash scripts/doctor.sh --profile normal
bash scripts/doctor.sh --profile normal --json | jq '.checks[] | select(.status != "ok")'
```

## Shell becomes minimal unexpectedly

Run `dotfiles-shell-diagnostics`. `remote=1` should only be caused by SSH or CI.
Being inside tmux sets `in_tmux=1` but does not reduce the feature mode.

Explicit overrides:

```bash
DOTFILES_SHELL_MODE=minimal zsh
DOTFILES_SHELL_MODE=full zsh
```

## tmux config does not reload

```bash
tmux source-file ~/.tmux.conf
tmux show-options -gqv @tmux_root
tmux display-message -p '#{config_file}'
```

Run the isolated smoke test without touching the active server:

```bash
bash scripts/test.sh --profile runtime
```

TPM is optional. Install it under `~/.tmux/plugins/tpm` and press `Prefix+I` to
install configured plugins.

## Clipboard paste is empty

Install one clipboard reader for the current platform:

- Wayland: `wl-paste`
- X11: `xclip`
- macOS: `pbpaste`
- WSL: PowerShell

Use `Prefix+p`; `Ctrl+V` belongs to the active application.

## Neovim first launch fails

Requirements:

- Neovim 0.11.3 or newer.
- Git available in `PATH`.
- Network access for the first lazy.nvim clone.

Recovery:

```bash
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
nvim
```

Disable network bootstrap for diagnostics:

```bash
DOTFILES_NVIM_BOOTSTRAP=0 nvim --headless -u nvim/.config/nvim/init.lua '+qa'
```

Then run `:checkhealth`, `:Lazy sync`, `:Mason` and `:ConformInfo` interactively.

## LazyGit cannot open a file or URL

Bootstrap links `scripts/open.sh` to `~/.local/bin/dotfiles-open`. Confirm that
`~/.local/bin` is in `PATH` and run:

```bash
dotfiles-open .
```

## WezTerm aesthetic mode has no background

Aesthetic features are opt-in and require the repository root in the GUI
environment:

```bash
export DOTFILES_ROOT=/absolute/path/to/dotfiles
export DOTFILES_WEZTERM_MODE=aesthetic
wezterm
```

Normal and minimal modes intentionally avoid media commands and asset scans.

## Git asks for identity

The public config intentionally does not contain personal identity:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
git config --show-origin --get-regexp '^user\.'
```

## LazyDocker warning

The Compose helper mounts `/var/run/docker.sock`. This grants the container
powerful Docker daemon access. Verify the image version before running:

```bash
LAZYDOCKER_VERSION=v0.25.2 docker compose run --rm lazydocker
```
