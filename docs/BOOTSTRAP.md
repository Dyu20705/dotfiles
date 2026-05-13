# Bootstrap Guide

## One-Command Installation

```bash
cd ~/.config/dotfiles
bash install.sh
```

This automates all bootstrap steps in order.

## Manual Bootstrap

### Step 1: System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  build-essential git curl wget \
  zsh bash tmux neovim nodejs npm \
  python3 python3-pip python3-dev \
  clang lldb lld clang-tools \
  rustc cargo \
  jq yq ripgrep fzf fd-find bat exa direnv \
  docker.io kubectl openssh-client openssh-server
```

**macOS:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install neovim tmux wezterm zsh bash \
  node ripgrep fzf fd bat eza starship zoxide atuin direnv just delta \
  llvm rust clang-tools cmake ninja jq yq kubectl docker
```

### Step 2: Rust/Cargo Tools

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install eza bat fd-find ripgrep fzf starship zoxide atuin just delta
```

### Step 3: NPM Tools

```bash
npm install -g bash-language-server typescript-language-server prettier
```

### Step 4: Clone Repository

```bash
git clone https://github.com/Dyu20705/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles
```

### Step 5: Backup Existing Configs

```bash
mkdir -p ~/dotfiles-backup
cp -r ~/.config/nvim ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.tmux.conf ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.zshrc ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.bashrc ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.config/git/config ~/dotfiles-backup/ 2>/dev/null || true
```

### Step 6: Create Symlinks

```bash
# Core configs
mkdir -p ~/.config
ln -sf ~/.config/dotfiles/nvim/.config/nvim ~/.config/nvim
ln -sf ~/.config/dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/.config/dotfiles/wezterm/wezterm.lua ~/.wezterm.lua
ln -sf ~/.config/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.config/dotfiles/bash/.bashrc ~/.bashrc
ln -sf ~/.config/dotfiles/git/.gitconfig ~/.gitconfig

# Infrastructure tools (optional)
mkdir -p ~/.config/{k9s,docker,kubectl}
ln -sf ~/.config/dotfiles/infra/k9s/config.yml ~/.config/k9s/config.yml 2>/dev/null || true
ln -sf ~/.config/dotfiles/infra/docker/config.json ~/.config/docker/config.json 2>/dev/null || true
```

### Step 7: Initialize Neovim

```bash
nvim +Lazy sync +q
# First launch auto-installs Lazy.nvim
# Second launch: manually install language servers
nvim +MasonInstall clangd pyright rust_analyzer yaml-language-server
```

### Step 8: Initialize Tmux

```bash
tmux new-session -d -s init
# Inside tmux session:
# Press: Ctrl+A I (capital I) to install TPM plugins
tmux kill-session -t init
```

### Step 9: Set Default Shell

```bash
chsh -s $(which zsh)
# Restart terminal/shell
```

### Step 10: Validate Installation

```bash
# Profile startup
time zsh -i -c exit
time nvim +q

# Check health
make diagnostics  # If Makefile exists
# OR manual checks:
bash scripts/diagnostics/check-startup.sh
bash scripts/diagnostics/check-lsp.sh
```

## Post-Bootstrap Customization

### Local Machine Overrides

Create file: `~/.config/dotfiles/local/machine-specific.zsh`

```bash
# Example local config
export MY_PROJECT_DIR="~/projects/my-infra"
export KUBECONFIG=~/.kube/config
export DOCKER_HOST="unix:///var/run/docker.sock"

# Machine-specific aliases
alias k='kubectl'
alias d='docker'
alias tf='terraform'
```

This file is automatically sourced and git-ignored.

### Neovim Local Overrides

Create file: `~/.config/nvim/init.local.lua`

```lua
-- Machine-specific Neovim config
-- Loaded after init.lua

-- Disable certain LSPs
require("lspconfig").tsserver.setup = function() end

-- Local keymaps
vim.keymap.set("n", "<Leader>mk", ":Make<CR>", { noremap = true })
```

## Troubleshooting Bootstrap

### Symlink Conflicts

```bash
# If symlink fails, backup and remove old config
mkdir -p ~/dotfiles-backup
mv ~/.config/nvim ~/dotfiles-backup/
ln -sf ~/.config/dotfiles/nvim/.config/nvim ~/.config/nvim
```

### Permission Denied

```bash
# Fix file permissions
chmod 600 ~/.gitconfig
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

### LSP Not Installing

```bash
# Manual LSP installation
nvim +MasonInstall bash-language-server yaml-language-server terraform-ls
# Check installed LSPs
nvim +Mason
```

### Tmux Plugin Issues

```bash
# Reset TPM
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux new-session -d -s test
# Inside tmux: Ctrl+A I
```

## Rollback

If something breaks after bootstrap:

```bash
# Restore from backup
cp -r ~/dotfiles-backup/nvim ~/.config/
cp ~/dotfiles-backup/.tmux.conf ~/.tmux.conf
cp ~/dotfiles-backup/.zshrc ~/.zshrc

# Or remove symlinks and use old configs
rm ~/.config/nvim ~/.tmux.conf ~/.zshrc
mkdir -p ~/.config/dotfiles/backup-old
mv ~/.config/nvim ~/.config/dotfiles/backup-old/
```

## Advanced: Scripted Bootstrap

For CI/CD or automation:

```bash
#!/bin/bash
set -euo pipefail

export DOTFILES_DIR="${HOME}/.config/dotfiles"

# Run automated bootstrap
${DOTFILES_DIR}/scripts/setup/install-nvim.sh
${DOTFILES_DIR}/scripts/setup/install-lsp.sh
${DOTFILES_DIR}/scripts/setup/install-tmux.sh
${DOTFILES_DIR}/scripts/setup/install-tools.sh

# Validate
bash ${DOTFILES_DIR}/scripts/diagnostics/check-startup.sh
```

See `scripts/setup/` for individual installers.
