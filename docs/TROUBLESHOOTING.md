# Troubleshooting

## Start with diagnostics

```bash
dot doctor
dot doctor --json | jq '.checks[] | select(.status != "ok")'
```

Before `dot` has been installed:

```bash
bash scripts/dot doctor --profile normal
```

## Zsh starts in minimal mode

```bash
dotfiles-shell-diagnostics
```

`remote=1` is set by SSH or CI. Being inside tmux sets `in_tmux=1` but does not
reduce a local normal session.

```bash
DOTFILES_SHELL_MODE=normal zsh
DOTFILES_SHELL_MODE=full zsh
```

Confirm the managed file is the repository Zsh config:

```bash
readlink -f ~/.zshrc
zsh -n ~/.zshrc
```

## An old Bash config is still active

The repository no longer deploys `.bashrc`, `.bash_profile`, `.bash_aliases` or
Bash completion files. Existing unmanaged Bash files in `HOME` are left alone.

Check ownership before removing anything:

```bash
ls -l ~/.bashrc ~/.bash_profile ~/.bash_aliases 2>/dev/null
dot doctor --json | jq '.checks[] | select(.target | test("bash"))'
```

Bash itself remains required to run repository scripts.

## tmux config does not reload

```bash
tmux source-file ~/.tmux.conf
tmux show-options -gqv @tmux_root
tmux display-message -p '#{config_file}'
bash scripts/test.sh --profile runtime
```

TPM is optional. Install/check it with:

```bash
bash scripts/install-tmux-plugins.sh --check
bash scripts/install-tmux-plugins.sh --install
```

## Clipboard paste is empty

Install the reader for the active environment:

- Wayland: `wl-paste`
- X11: `xclip`
- macOS: `pbpaste`
- WSL: PowerShell

Use `Prefix+p`. `Ctrl+V` remains owned by the active application.

## Neovim first launch fails

Requirements:

- Neovim 0.11.3 or newer;
- Git in `PATH`;
- network access for the first lazy.nvim clone.

Recovery:

```bash
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
nvim
```

Headless diagnostic:

```bash
DOTFILES_NVIM_BOOTSTRAP=0 \
  nvim --headless -u nvim/.config/nvim/init.lua '+qa'
```

Then run `:checkhealth`, `:Lazy sync`, `:Mason` and `:ConformInfo`.

## LazyGit cannot open a file or URL

```bash
command -v dotfiles-open
dotfiles-open .
```

`dotfiles-open` selects the platform opener. `~/.local/bin` must be in `PATH`.

## Git and LazyGit appear inconsistent

LazyGit operates on the same repository and Git configuration as the CLI.

```bash
git config --show-origin --list
git status
lazygit
```

LazyGit auto-fetch is disabled. Run explicit network operations with Git when
you need exact control:

```bash
git fetch --prune --prune-tags
git pull --ff-only
```

## WezTerm has no background or media controls

```bash
bash scripts/check-wezterm.sh
```

Set machine-local paths:

```bash
export DOTFILES_WEZTERM_BG_DIR="$HOME/Pictures/backgrounds"
export DOTFILES_WEZTERM_MUSIC_DIR="$HOME/Music"
export DOTFILES_WEZTERM_DEFAULT_TRACK="$HOME/Music/default.mp3"
```

Supported backgrounds are PNG, JPEG and WebP. Music requires `mpv`; volume uses
`wpctl` and falls back to `pactl`. Minimal mode intentionally disables asset
discovery and media actions.

## Git asks for identity

The public config intentionally omits identity:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
git config --show-origin --get-regexp '^user\.'
```

## LazyDocker warning

Prefer a native LazyDocker release. The optional Compose helper mounts the
Docker socket and therefore has powerful control over the Docker daemon.

```bash
docker compose run --rm lazydocker
```

Run only a trusted image and verify any overridden tag before use.
