# Debian dotfiles

A small personal configuration for **Kitty, tmux and Neovim** on Debian.
The repository intentionally avoids a custom shell, plugin managers, background
services and a general-purpose dotfiles framework.

## Install packages

```bash
sudo apt update
sudo apt install kitty tmux neovim
```

## Deploy configurations

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Preview what will happen first.
./install.sh --dry-run

# Back up existing targets and create symlinks.
./install.sh
```

The installer does not use `sudo`, install packages, change your login shell,
or delete existing configuration. Existing targets are moved next to their
original paths with a `.backup.<timestamp>` suffix.

Because the files are symlinked, changes pulled into `~/dotfiles` take effect
without running the installer again. Run it again only when deploying to a new
machine or repairing links.

## What is configured

- **Kitty:** modest window padding, scrollback, quiet bell and a few tab/window
  shortcuts. The terminal's default font and color scheme are retained.
- **tmux:** Ctrl-a prefix, mouse support, vi copy mode, current-directory-aware
  splits, pane navigation, OSC 52 clipboard forwarding and a minimal status bar.
- **Neovim:** sensible editing/search defaults and a small set of leader
  keymaps. It uses built-in features and starts without third-party plugins.

## Clipboard notes

Kitty supports OSC 52 clipboard writes. tmux enables clipboard forwarding so
copying text in tmux copy mode can reach the local clipboard. Neovim's `+` and
`*` registers use a system clipboard provider; install one only when needed:

```bash
# Wayland
sudo apt install wl-clipboard

# X11
sudo apt install xclip
```

## Extend only when needed

Keep each application's configuration in its own directory. Add a plugin or
helper only after a repeated workflow cannot be handled cleanly by the built-in
features. Neovim can load plugins from its native `pack/*/start` layout; a
plugin manager is not a prerequisite. Add language servers individually when
there is a concrete language/toolchain requirement.

Do not add machine-specific paths, credentials, tokens or private keys to this
repository. Keep those in local files outside Git.

## Useful checks

```bash
# Outside tmux, Kitty should normally report xterm-kitty.
echo "$TERM"

# Inside tmux, this should report tmux-256color.
echo "$TERM"

# Check Neovim's runtime and built-in health checks.
nvim --version
nvim --clean +'checkhealth' +q
```
