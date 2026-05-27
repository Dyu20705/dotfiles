# Dotfiles

> A comprehensive, modern dotfiles configuration for advanced terminal users, developers, and system programmers. Features a fully-integrated Neovim ecosystem, tmux multiplexing, wezterm terminal emulator, and production-grade developer tooling.

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green?logo=neovim&logoColor=white)
![Tmux](https://img.shields.io/badge/Tmux-3.0+-blue?logo=tmux&logoColor=white)
![Wezterm](https://img.shields.io/badge/Wezterm-Latest-purple)
![Shell](https://img.shields.io/badge/Shell-Zsh%20%2F%20Bash-red?logo=gnu-bash)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## Overview

This repository contains a **production-grade, modular dotfiles configuration** optimized for system engineers, DevOps practitioners, and infrastructure developers. It emphasizes reproducibility, observability, automation, and high-performance terminal workflows.

**Primary Focus**: System/Infrastructure Engineering

- **Modular architecture** with clear separation: config, scripts, bootstrap, infra, security, monitoring
- **Infrastructure tooling**: Kubernetes (k9s), Docker (lazydocker), Terraform, Ansible, SSH multiplexing
- **System observability**: Performance monitoring, debugging tools, diagnostic scripts
- **Neovim IDE** with LSP/DAP for systems programming (C, Rust, Zig, Bash, Docker, YAML, Terraform)
- **Terminal productivity**: Shell tooling (zoxide, fzf, atuin, ripgrep, eza, delta)
- **Automation-first**: Bootstrap scripts, install automation, config validation, health checks
- **Keyboard-driven**: Vim-based navigation, tmux multiplexing, efficient workflows
- **Fast startup**: Lazy-loading, minimal overhead, profiling tools

Designed for **Ubuntu/Debian-based Linux** and macOS. Achieves reproducibility through version-pinned dependencies and declarative configuration.

---

## Design Principles

This configuration follows **8 core principles** for production-grade infrastructure environments:

1. **Reproducible** – Version-pinned dependencies, declarative configs, portable across machines
2. **Modular** – Independent components with clear responsibilities; modify one without breaking others
3. **Observable** – Built-in diagnostics, profiling, health checks, debug tooling
4. **Scriptable** – Automation-first; bootstraps, install scripts, validation checks
5. **Fast Startup** – Lazy-loading plugins, caching, minimal overhead; < 100ms shell startup
6. **Keyboard-Driven** – Vim-like navigation throughout; efficient workflows for power users
7. **Debugging-Friendly** – Tools for inspection, profiling, system introspection, log analysis
8. **Automation-First** – Infrastructure as code, config management, provisioning scripts

---

## Core Features

### System/Infrastructure Focus
- **Infrastructure-aware tooling**: k9s (Kubernetes UI), lazydocker (Docker TUI), Terraform LSP
- **Network debugging**: tcpdump, dig, doggo (DNS), xh (HTTP client)
- **System profiling**: perf, hyperfine, iotop, strace/ltrace
- **Disk/IO analysis**: ncdu, dust, iotop
- **Monitoring**: btop, fastfetch, htop integration
- **SSH workflow**: SSH config management, agent, multiplexing, jump hosts
- **Git infrastructure**: Signed commits, delta diff, worktree helpers, interactive rebasing

## Features

### Neovim IDE
- **LSP-driven development** with Mason auto-installer for language servers (C/C++, Rust, Python, Zig, Docker)
- **DAP integration** with breakpoints, variable inspection, and conditional debugging (F5/F10/F11/F12)
- **Advanced completion** with cmp, luasnip, and intelligent context
- **Testing framework** via neotest with test runners
- **Git workflows** with Neogit (interactive staging) and Gitsigns (inline blame/hunks)
- **Intelligent search** via Telescope with fzf acceleration and live grep
- **Session persistence** with auto-session (automatically save/restore buffer state)
- **Code quality** with Treesitter (syntax-aware editing), Nvim-lint, and Conform (format on save)
- **Project-aware navigation** with Neo-tree, Aerial (symbol outline), and Trouble (diagnostic panel)
- **Terminal inside editor** via ToggleTerm for quick shell access
- **Undo tree visualization** and pattern replacement with Spectre
- **Code generation** with AI-assisted snippets and templates

### Tmux Multiplexing
- **Vim keybindings** throughout (hjkl navigation, Vi copy-mode)
- **Smart pane splitting** with working directory preservation
- **Native tmux UI** with deterministic status, workspace context, and pane metadata
- **Seamless Vim↔Tmux navigation** via christoomey/vim-tmux-navigator
- **Session resurrection** with tmux-resurrect (manual save/restore only)
- **System integration** via tmux-yank (OS-aware copy/paste detection)
- **Workspace orchestration** via session-manager and diagnostics scripts
- **Clipboard and editor helpers** stay explicit instead of running in status polling

### Wezterm Terminal
- **GPU-accelerated rendering** with true color support (24-bit)
- **Catppuccin theme** with customizable opacity
- **Dynamic background slideshow** (5-minute rotation)
- **Ambient background music** with OS-aware playback (mpv)
- **Tab management** with customizable appearance
- **Font flexibility** (Nerd Font support for icons)
- **OS-specific copy/paste** detection (wayland, X11, macOS)

### Shell Configuration (Fast & Modular)
- **Zsh & Bash** with modular sourcing (exports, aliases, functions, completion, plugins)
- **Shell tooling integration**:
  - `zoxide` – Smarter cd (z command)
  - `eza` – Modern ls replacement
  - `bat` – Code-aware cat
  - `fd` – Find replacement
  - `ripgrep` – Ultra-fast grep
  - `fzf` – Fuzzy finder (files, history, processes)
  - `atuin` – Powerful shell history search
  - `starship` – Fast, zero-latency prompt
  - `direnv` – Automatic environment management
  - `delta` – Beautiful git diffs
  - `just` – Modern make alternative
  - `jq/yq` – JSON/YAML processing
- **Git integration** with vim/nvim as editor
- **Startup profiling** and performance monitoring
- **PATH hygiene** with no duplicates

### Custom Automation & Scripts
- **Installer** (`install.sh`) – One-command dotfiles bootstrap
- **Bootstrap script** (`bootstrap.sh`) – System setup, dependency install, symlink management
- **Backup/restore** – Automatic config backup before changes, rollback capability
- **Health diagnostics** – Startup profiling, LSP validation, config syntax checking
- **Pomodoro timer** (`pomodoro.sh`) – Configurable intervals with notifications
- **Random note picker** (`random_note.sh`) – Task suggestion from todo files
- **Git helpers** – Branch management, commit signing, worktree automation
- **Sync script** – Machine-to-machine config synchronization
- **Makefile** – Task automation (make install, make bootstrap, make diagnostics)

---

## Tech Stack Overview

### Core Components

| Category | Tool | Purpose | Version |
|----------|------|---------|---------|
| **Editor** | Neovim | Systems-focused IDE | 0.9+ |
| **Shell** | Zsh + Bash | Interactive shell | Latest |
| **Multiplexer** | Tmux | Terminal sessions | 3.0+ |
| **Terminal** | Wezterm | GPU-accelerated emulator | Latest |
| **Plugin Manager** | Lazy.nvim | Neovim plugin loading | Latest |
| **LSP Manager** | Mason.nvim | Language server installer | Latest |
| **Prompt** | Starship | Fast cross-shell prompt | Latest |
| **Theme** | Catppuccin | Consistent colors | Mocha |

### Shell Tooling (Productivity)

| Tool | Function | Replace |
|------|----------|---------|
| **zoxide** | Smart directory navigation | `cd` |
| **eza** | Modern file listing | `ls` |
| **bat** | Syntax-highlighted viewing | `cat` |
| **fd** | Fast file finding | `find` |
| **ripgrep (rg)** | Ultra-fast text search | `grep` |
| **fzf** | Fuzzy finder (files, history, etc) | N/A (addon) |
| **atuin** | Enhanced shell history | `history` |
| **direnv** | Automatic environment loading | N/A |
| **delta** | Beautiful git diffs | `git diff` |
| **just** | Task runner | `make` |
| **jq** | JSON processor | N/A |
| **yq** | YAML processor | N/A |
| **thefuck** | Command auto-correction | N/A |
| **tldr** | Quick command docs | `man` (fast) |

### Infrastructure & System Tools

| Tool | Purpose | Use Case |
|------|---------|----------|
| **k9s** | Kubernetes dashboard (TUI) | Cluster management |
| **lazydocker** | Docker UI (TUI) | Container management |
| **lazygit** | Git UI (TUI) | Interactive git operations |
| **btop/bottom** | System monitor (top replacement) | Performance monitoring |
| **fastfetch** | System info display | Quick system overview |
| **ncdu** | Disk usage analyzer | Storage analysis |
| **dust** | Intuitive du (disk usage) | Fast disk inspection |
| **hyperfine** | Command benchmarking | Performance profiling |
| **perf** | Linux profiler | Advanced profiling |
| **strace/ltrace** | System call tracing | Debugging & analysis |
| **tcpdump** | Network packet capture | Network debugging |
| **dig** | DNS lookup tool | DNS queries |
| **doggo** | Modern dig alternative | DNS inspection |
| **xh** | HTTP client (curl replacement) | HTTP testing |
| **bandwhich** | Bandwidth monitor | Network analysis |

### Neovim LSP Support

| Language | LSP | Debugger | Formatter | Linter |
|----------|-----|----------|-----------|--------|
| **C/C++** | clangd | lldb | clang-format | clang-tidy |
| **Rust** | rust-analyzer | lldb | rustfmt | clippy |
| **Python** | pyright | debugpy | black | pylint |
| **Zig** | zls | zig-debug | zig fmt | - |
| **Bash** | bash-language-server | bashdb | shfmt | shellcheck |
| **YAML** | yaml-language-server | - | yamlfmt | yamllint |
| **Terraform** | terraform-ls | - | terraform fmt | - |
| **Ansible** | ansible-language-server | - | - | - |
| **Docker** | dockerfile-language-server | - | - | hadolint |
| **Nginx** | nginx-language-server | - | - | - |
| **Markdown** | marksman | - | prettier | markdownlint |
| **JSON** | jsonls | - | prettier | - |
| **TOML** | taplo | - | - | - |
| **Go** | gopls | dlv | gofmt | golangci-lint |
| **Node.js** | ts-node-debug | node-debug | prettier | eslint |

---

## Repository Structure

```
dotfiles/
├── README.md                      # This file
├── LICENSE
├── .gitignore
├── install.sh                     # Main installer
├── bootstrap.sh                   # System bootstrap script
├── Brewfile                       # macOS dependencies
├── packages.txt                   # Linux dependencies
├── Makefile                       # Task automation
│
├── assets/                        # Media & screenshots
│   ├── preview.png
│   └── screenshots/
│
├── scripts/                       # Automation & utilities
│   ├── setup/                     # Installation scripts
│   │   ├── install-nvim.sh
│   │   ├── install-lsp.sh
│   │   ├── install-tmux.sh
│   │   └── install-tools.sh
│   ├── backups/                   # Backup routines
│   │   ├── backup-config.sh
│   │   └── restore-config.sh
│   ├── diagnostics/               # Health checks
│   │   ├── check-startup.sh
│   │   ├── check-lsp.sh
│   │   └── profile-nvim.sh
│   ├── sync/                      # Machine sync
│   ├── git/                       # Git helpers
│   ├── tmux/                      # Tmux scripts
│   └── utils/                     # General utilities
│
├── docs/                          # Documentation
│   ├── ARCHITECTURE.md            # System design
│   ├── WORKFLOW.md                # Daily workflows
│   ├── KEYBINDINGS.md             # Comprehensive keybinds
│   ├── TROUBLESHOOTING.md         # Problem solving
│   ├── PERFORMANCE.md             # Profiling guide
│   ├── INFRA-GUIDE.md             # System/infra workflows
│   └── BOOTSTRAP.md               # Setup instructions
│
├── shell/                         # Shell configuration
│   ├── bash/
│   │   └── .bashrc
│   └── zsh/
│       ├── .zshrc                 # Main entry
│       ├── exports.zsh            # Environment variables
│       ├── aliases.zsh            # Command aliases
│       ├── functions.zsh          # Shell functions
│       ├── completion.zsh         # Completions
│       ├── plugins.zsh            # Plugin configuration
│       ├── prompt.zsh             # Starship prompt
│       └── paths.zsh              # PATH configuration
│
├── nvim/                          # Neovim IDE
│   └── .config/nvim/
│       ├── init.lua               # Bootstrap
│       ├── lazy-lock.json         # Lockfile
│       ├── lua/
│       │   ├── core/              # Core settings
│       │   ├── plugins/           # Plugin specs (28 plugins)
│       │   ├── lsp/               # LSP configurations
│       │   ├── dap/               # Debug config
│       │   ├── ui/                # UI plugins
│       │   ├── utils/             # Utility functions
│       │   ├── commands/          # Custom commands
│       │   └── autocmds/          # Autocommands
│       ├── after/                 # Post-load configs
│       ├── ftplugin/              # Filetype plugins
│       ├── snippets/              # Luasnip templates
│       └── spell/                 # Spell files
│
├── tmux/                          # Terminal multiplexer
│   ├── tmux.conf                  # Main config
│   ├── plugins/                   # TPM plugins
│   ├── themes/                    # Theme configs
│   ├── scripts/                   # Helper scripts
│   └── Ringing.mp3                # Alert sound
│
├── wezterm/                       # Terminal emulator
│   ├── wezterm.lua                # Main config
│   ├── modules/                   # Lua modules
│   ├── themes/                    # Color schemes
│   ├── utils/                     # Utilities
│   ├── bg/                        # Backgrounds (git-ignored)
│   └── sd/                        # Sound files (git-ignored)
│
├── git/                           # Git configuration
│   ├── .gitconfig                 # Main config
│   ├── .gitignore_global          # Global ignores
│   ├── commits/                   # Commit templates
│   └── hooks/                     # Git hooks
│
├── infra/                         # Infrastructure tools
│   ├── ssh/                       # SSH config
│   ├── kubectl/                   # Kubernetes config
│   ├── docker/                    # Docker config
│   ├── k9s/                       # K9s UI config
│   ├── terraform/                 # Terraform config
│   ├── ansible/                   # Ansible config
│   └── tailscale/                 # Tailscale config
│
├── monitoring/                    # System monitoring
│   ├── btop/                      # System monitor
│   ├── fastfetch/                 # System info
│   ├── htop/                      # Process monitor
│   └── logs/                      # Log configs
│
├── security/                      # Security configs
│   ├── gpg/                       # GPG config
│   ├── age/                       # Age encryption
│   ├── ssh/                       # SSH keys (git-ignored)
│   └── secrets.example/           # Secrets template
│
└── local/                         # Machine-specific
    ├── machine-specific.zsh       # Local overrides (git-ignored)
    └── ignored/                   # Local files (git-ignored)
```

### Directory Responsibilities

| Directory | Purpose |
|-----------|----------|
| **scripts/** | Automation: setup, backups, diagnostics, sync, helpers |
| **docs/** | Comprehensive documentation, guides, architecture |
| **shell/** | Modular shell config (zsh/bash) with lazy loading |
| **nvim/** | Neovim IDE with LSP/DAP for systems programming |
| **tmux/** | Session multiplexing, plugins, themes |
| **wezterm/** | GPU-accelerated terminal, modular config |
| **git/** | Version control config, aliases, hooks |
| **infra/** | Infrastructure tools (k8s, Docker, Terraform, Ansible) |
| **monitoring/** | System observability (btop, fastfetch, logs) |
| **security/** | GPG, SSH, age encryption, secrets management |
| **local/** | Machine-specific overrides (git-ignored) |

---

## Installation Guide

### Prerequisites (Ubuntu/Debian)

```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install build essentials & dependencies
sudo apt install -y \
  build-essential git curl wget \
  zsh bash tmux neovim nodejs npm \
  python3 python3-pip python3-dev \
  clang lldb lld clang-tools \
  rustc cargo \
  jq yq \
  ripgrep fzf fd-find bat exa direnv \
  tmux wezterm \
  docker.io docker-compose-plugin kubectl \
  openssh-client openssh-server

# Install cargo-based tools (Rust ecosystem)
cargo install eza bat fd-find ripgrep fzf starship zoxide atuin just delta

# Install npm-based tools
npm install -g bash-language-server typescript-language-server prettier

# Clone dotfiles
git clone https://github.com/Dyu20705/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles
```

### macOS Prerequisites

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install core tools
brew install neovim tmux wezterm zsh bash \
  node ripgrep fzf fd bat eza starship zoxide atuin direnv just delta \
  llvm rust clang-tools cmake ninja \
  jq yq kubectl docker

brew tap FrangipaneTeam/tap
brew install btop

# Clone dotfiles
git clone https://github.com/Dyu20705/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles
```

### One-Command Bootstrap (Recommended)

```bash
cd ~/.config/dotfiles
bash install.sh
```

This script will:
1. ✓ Backup existing configs
2. ✓ Create symlinks
3. ✓ Install dependencies via package manager
4. ✓ Install language servers via Mason
5. ✓ Initialize Tmux plugins
6. ✓ Validate all configs
7. ✓ Run diagnostics

### Manual Installation

**Step 1: Backup existing configs**
```bash
mkdir -p ~/dotfiles-backup
cp -r ~/.config/nvim ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.tmux.conf ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.zshrc ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.config/git/config ~/dotfiles-backup/ 2>/dev/null || true
```

**Step 2: Create symlinks**
```bash
# Symlink main configs
ln -sf ~/.config/dotfiles/nvim/.config/nvim ~/.config/nvim
ln -sf ~/.config/dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/.config/dotfiles/wezterm/wezterm.lua ~/.wezterm.lua
ln -sf ~/.config/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.config/dotfiles/bash/.bashrc ~/.bashrc
ln -sf ~/.config/dotfiles/git/.gitconfig ~/.gitconfig

# Symlink infra tools (optional)
mkdir -p ~/.config/k9s ~/.config/docker
ln -sf ~/.config/dotfiles/infra/k9s/config.yml ~/.config/k9s/config.yml 2>/dev/null || true
ln -sf ~/.config/dotfiles/infra/docker/config.json ~/.config/docker/config.json 2>/dev/null || true
```

**Step 3: Install shell tools**
```bash
# Via cargo/npm (see prerequisites above)
# OR system package manager:
sudo apt install -y eza bat fd-find ripgrep fzf starship zoxide atuin direnv
```

**Step 4: Initialize Neovim**
```bash
# First launch auto-installs Lazy.nvim
nvim
# Inside Neovim: :Lazy sync (auto-runs on startup)
# Install language servers: :MasonInstall clangd pyright rust_analyzer
```

**Step 5: Initialize Tmux plugins**
```bash
tmux new-session -d -s init
# Inside tmux: Ctrl+A I (capital I)
# This runs TPM and installs all plugins
```

**Step 6: Set shell to Zsh**
```bash
chsh -s $(which zsh)
# Restart shell/terminal
```

**Step 7: Validate setup**
```bash
# Run diagnostics
bash scripts/diagnostics/check-startup.sh
bash scripts/diagnostics/check-lsp.sh

# Profile startup times
time zsh -i -c exit
time nvim +q
```

---

## Bootstrap & Post-Install Steps

### 1. First Nvim Launch

```bash
nvim
```

Lazy.nvim will automatically:
- Clone plugins from the plugin specs
- Install language servers via Mason (configure in `plugins/lsp-config.lua`)
- Download tree-sitter parsers
- Create initial directories

This may take 2–3 minutes on first run. Subsequent launches are instant.

### 2. Configure Tmux Plugin Manager

Open tmux and install plugins:

```bash
tmux new-session -d -s init
# Inside tmux:
prefix + I      # Ctrl+A I (capital I)
```

This runs `~/.tmux/plugins/tpm/tpm.sh` and clones all plugin repos.

### 3. Wezterm Setup

Create directories for backgrounds and music:

```bash
mkdir -p ~/dotfiles/wezterm/bg
mkdir -p ~/dotfiles/wezterm/sd

# Add background images (jpg/png)
cp ~/Pictures/my-background.png ~/dotfiles/wezterm/bg/

# Add background music (mp3/flac/wav/m4a)
cp ~/Music/ambient.mp3 ~/dotfiles/wezterm/sd/
```

Music plays automatically; backgrounds rotate every 5 minutes.

### 4. Language Servers

Neovim will attempt to auto-install via Mason when you open files:

```bash
# Manually trigger installation
nvim +MasonInstall clangd pyright rust_analyzer zls
```

For C/C++, also install system clang:

```bash
# macOS
brew install llvm

# Ubuntu
sudo apt install clang lldb clang-format

# Arch
sudo pacman -S clang lldb
```

### 5. Shell Configuration

Set Zsh as default shell:

```bash
# macOS
chsh -s $(which zsh)

# Linux
chsh -s /usr/bin/zsh
# Enter your password when prompted
```

Restart terminal/shell for changes to take effect.

---

## Modularity & Customization

### Local Overrides

Create machine-specific configs without modifying tracked files:

```bash
# Zsh local overrides
cat ~/.config/dotfiles/local/machine-specific.zsh
# Add: export MY_CUSTOM_VAR="value"
# Automatically sourced by .zshrc at startup

# Nvim local overrides
# Create: ~/.config/nvim/init.local.lua
# Automatically loaded after init.lua
```

### Modular Shell Configuration

Zsh is split into logical modules:

```
zsh/
├── .zshrc            # Main entry (sources modules)
├── exports.zsh       # Environment variables (lazy-loaded)
├── aliases.zsh       # Command aliases (no startup cost)
├── functions.zsh     # Shell functions (lazy-loaded)
├── completion.zsh    # Completions (async-loaded)
├── plugins.zsh       # Plugin manager (lazy-loaded)
├── prompt.zsh        # Starship config (fast init)
└── paths.zsh         # PATH configuration (careful ordering)
```

Disable modules by adding `.disabled` suffix:
```bash
mv zsh/completion.zsh zsh/completion.zsh.disabled
```

### Neovim Plugin Disabling

To disable a plugin without deletion:

```bash
mv nvim/.config/nvim/lua/plugins/wakatime.lua nvim/.config/nvim/lua/plugins/wakatime.lua.disabled
# Lazy.nvim ignores .disabled files
```

Or edit the spec directly:
```lua
-- In plugins/plugin-name.lua
return {
  "author/plugin",
  enabled = false,  -- Completely disabled
}
```

---

## Diagnostics & Performance Profiling

### Startup Performance

**Profile shell startup:**
```bash
time zsh -i -c exit          # Total time
for i in {1..10}; do time zsh -i -c exit; done  # Average
```

**Profile Neovim startup:**
```bash
time nvim +q                 # Total startup
nvim --startuptime /tmp/startup.log +q
cat /tmp/startup.log | head -20
```

**Profile Tmux:**
```bash
time tmux -S /tmp/test attach  # Session load time
```

### Health Checks

```bash
# Run all diagnostics
make diagnostics

# Check specific components
bash scripts/diagnostics/check-startup.sh    # Shell startup
bash scripts/diagnostics/check-lsp.sh        # LSP servers
bash scripts/diagnostics/profile-nvim.sh     # Neovim profiling
```

### LSP Validation

```bash
# Inside Neovim
:checkhealth nvim
:checkhealth nvim.lsp
:MasonInstallAll
:Mason
```

### Config Validation

```bash
# Validate Lua syntax
lua -l luac -p ~/.config/nvim/init.lua

# Validate Zsh syntax
zsh -n ~/.zshrc

# Validate Tmux config
tmux source-file -q ~/.tmux.conf && echo "✓ Valid"
```

---

## System/Infrastructure Workflows

### Kubernetes Operations

```bash
# K9s dashboard (TUI for cluster management)
k9s

# Neovim with Terraform/YAML support
nvim deployment.yaml        # Full LSP support
nvim terraform/main.tf
```

### Docker & Container Management

The root `docker-compose.yaml` defines a `lazydocker` service that mounts the Docker socket and persists its config under `~/.config/jesseduffield/lazydocker`.

```bash
# Lazydocker TUI via Docker Compose
docker compose run --rm lazydocker

# If your system still exposes the legacy binary name
docker-compose run --rm lazydocker

# Terminal with Dockerfile LSP
nvim Dockerfile
```

### Git Infrastructure

```bash
# Interactive git UI
lazygit

# Signed commits (configured in .gitconfig)
git commit -S -m "message"  # Automatically signed

# Beautiful diffs (delta)
git diff

# Worktree helpers
git worktree add ../feature-x
```

### Network Debugging

```bash
# DNS queries
doggo example.com

# HTTP testing
xh GET https://api.example.com

# Packet capture
tcpdump -i eth0 -n port 8080

# Bandwidth monitoring
bandwhich
```

### System Profiling

```bash
# CPU profiling
perf record ./my-app
perf report

# Benchmark commands
hyperfine './solution-1.sh' './solution-2.sh'

# System trace
strace -e trace=network ./my-app

# Disk usage
ncdu ~/
dust ~/

# Top alternative
btop
```

---

## OS-Specific Notes

### macOS

- Wezterm uses macOS-native window management; respects Mission Control
- Copy/paste via `pbpaste` (built-in)
- Font rendering uses system CoreText (excellent quality)
- Background music uses `afplay` instead of `paplay`
- Requires full disk access for some features (System Preferences → Security & Privacy)

### Linux (Wayland / X11)

**Wayland** (GNOME, KDE Plasma 6+):
- Copy/paste uses `wl-paste` / `wl-copy`
- Ensure `wl-clipboard` package is installed
- GPU acceleration may be limited on some desktop environments

**X11** (traditional):
- Copy/paste uses `xclip` or `xsel`
- Better GPU acceleration support
- May have performance issues with large terminal buffers

**Audio**:
- PipeWire systems use `paplay` (recommended)
- Fallback to `pactl play-file` if unavailable
- Verify audio device: `pactl list short sinks`

---

## Keybindings Overview

### Neovim (Leader = Space)

| Keybinding | Action |
|----------|--------|
| `<Leader>ff` | Find files (Telescope) |
| `<Leader>fg` | Live grep (Telescope) |
| `<Leader>fb` | Buffers (Telescope) |
| `<Leader>fh` | Help tags (Telescope) |
| `<F5>` / `<F10>` / `<F11>` / `<F12>` | Debug (continue/step-over/step-into/step-out) |
| `<Leader>b` | Toggle breakpoint |
| `<Leader>B` | Conditional breakpoint |
| `gcc` | Toggle line comment (comment.nvim) |
| `gc` (visual) | Toggle block comment |
| `cs` | Change surround (vim-surround) |
| `<C-/>` | Toggle terminal (toggleterm) |
| `:NeotreeToggle` | File tree sidebar |
| `:AerialToggle` | Symbols outline |
| `:TroubleToggle` | Diagnostics panel |
| `:Telescope oldfiles` | Recent files |

### Tmux (Prefix = Ctrl+A)

| Keybinding | Action |
|----------|--------|
| `C-a` | Send Ctrl+A to application |
| `\|` | Split pane horizontally |
| `-` | Split pane vertically |
| `hjkl` | Resize pane (hold repeat) |
| `m` | Maximize/minimize pane |
| `c` | New window (preserve pwd) |
| `C-r` | Reload config file |
| `C-v` | Paste from clipboard |
| `e` | New split with daily notes in nvim |
| `o` | New split with todo list in nvim |
| `v` | New split with nvim (full shell) |
| `C-s` | Save session (resurrect) |
| `C-r` (in resurrect context) | Restore session |

### Wezterm

| Keybinding | Action |
|----------|--------|
| `Alt+1`, `Alt+2`, etc. | Switch tab |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Shift+N` | New window |
| `Ctrl+Shift+K` | Kill pane |
| `Alt+J`, `Alt+K` | Scroll history |

---

## Neovim Ecosystem & Plugins

### Plugin Categories

**Editor Features**:
- `catppuccin.nvim` – Warm, soothing color scheme
- `lualine.nvim` – Lightweight status bar
- `which-key.nvim` – Keybinding discovery
- `mini.indentscope` – Indent guides

**Navigation & Search**:
- `telescope.nvim` – Fuzzy finder (files, buffers, grep)
- `neotree.nvim` – File browser sidebar
- `aerial.nvim` – Symbol outline (LSP-aware)

**Code Editing**:
- `nvim-autopairs` – Auto-pair brackets
- `nvim-surround` – Surround text operations
- `nvim-comment` – Toggle comments
- `conform.nvim` – Format code (async)
- `nvim-lint` – Async linting

**Completion & Snippets**:
- `nvim-cmp` – Completion engine
- `luasnip` – Snippet engine
- `cmp-nvim-lsp` – LSP completion source
- `cmp-buffer`, `cmp-path` – Buffer/path completion

**LSP & Debugging**:
- `nvim-lspconfig` – LSP client configuration
- `mason.nvim` – Language server installer
- `nvim-dap` – Debug Adapter Protocol
- `nvim-dap-ui` – DAP visual interface

**Version Control**:
- `neogit` – Git staging/committing (interactive)
- `gitsigns.nvim` – Inline blame, hunks, line-by-line diff

**Testing & Quality**:
- `neotest` – Test runner framework
- `trouble.nvim` – Diagnostic panel (organized)

**Productivity**:
- `nvim-tree.lua` – File explorer (legacy, consider removing)
- `toggleterm.nvim` – Embedded terminal
- `undotree` – Undo history visualization
- `spectre.nvim` – Find and replace (project-wide)
- `auto-session` – Session persistence
- `auto-tag` – Auto-close HTML/XML tags
- `wakatime.nvim` – Code time tracking

### Plugin Architecture

Plugins follow **Lazy.nvim** lazy-loading:

```lua
-- Example plugin spec
return {
  "author/plugin-name",
  event = "VeryLazy",           -- Load on VeryLazy event
  dependencies = { "other/dep" },
  config = function()
    require("plugin-name").setup({ ... })
  end,
}
```

Benefits:
- Startup time < 50ms (without plugins loaded)
- On-demand loading based on file types, events, or commands
- Dependency resolution automatic

---

## Terminal Workflow

### Session Management

**Create a new session**:
```bash
tmux new-session -s work
```

**List sessions**:
```bash
tmux list-sessions   # or: tmux ls
```

**Attach to session**:
```bash
tmux attach -t work
```

**Detach from session** (keep running):
```
Ctrl+A d
```

### Split Panes & Windows

**Split horizontally** (`Ctrl+A |`):
```
└─ Pane 1 │ Pane 2
```

**Split vertically** (`Ctrl+A -`):
```
├─ Pane 1
└─ Pane 2
```

**Navigate panes** with `Ctrl+hjkl` (vim-tmux-navigator):
```
Ctrl+H/J/K/L between panes and Vim windows seamlessly
```

**Resize pane** (hold and repeat):
```
Ctrl+A + hjkl (resize)
Ctrl+A + m    (maximize)
```

### Persistent Sessions

Sessions auto-save every 15 minutes (via tmux-continuum):

```bash
# Manual save
Ctrl+A C-s

# Manual restore
Ctrl+A C-r
```

Resurrection saves:
- Open windows/panes
- Active directory per pane
- Vim/Neovim sessions (if using `:mksession`)
- Shell history

---

## Development Workflow

### Daily Development Loop

1. **Start session** (or attach existing):
   ```bash
   tmux new-session -s dev -c ~/Projects/myapp
   ```

2. **Open editor in main pane**:
   ```bash
   nvim src/main.py
   ```

3. **Create auxiliary panes** for build/test:
   - `Ctrl+A |` – Split for `make watch` or `cargo build`
   - `Ctrl+A -` – Split for `pytest` or test watcher

4. **Debug with DAP**:
   - Set breakpoint: `<Leader>b`
   - Start debugging: `<F5>`
   - Step through: `<F10>` (over), `<F11>` (into)
   - Inspect variables in DAP UI

5. **Stage & commit with Neogit**:
   - `:Neogit` in Nvim
   - `s` to stage hunks
   - `c` to commit
   - `:q` to close

6. **Search & replace**:
   - `<Leader>sr` in Spectre
   - or `<Leader>fg` with Telescope live-grep

7. **Run tests**:
   - `:Neotest run` (nearest test)
   - `:Neotest run file` (all in file)
   - Results in floating window

### Git Workflow

**Stage interactively**:
```bash
nvim              # Open editor
:Neogit           # Open git ui
# Navigate to hunks, press 's' to stage
# or 'S' to stage file
# press 'c' to commit
```

**View blame inline**:
```
:Gitsigns blame_line
```

**Navigate hunks**:
```bash
]c  # Next hunk
[c  # Previous hunk
```

### Language-Specific Workflows

**Python**:
```bash
# Auto-format with black
:Conform

# Run linter
:Lint

# Run tests with neotest
:Neotest run
```

**Rust**:
```bash
# Check compilation
:!cargo check

# Build and run
:!cargo run

# Debug
<F5>  (if DAP configured for rust-lldb)
```

**C/C++**:
```bash
# Use clangd LSP (auto-installed)
# Hover for type info: K
# Go to definition: gd
# Find references: gr

# Debug
<F5> (with clang/lldb)
```

---

## Automation Scripts

### Pomodoro Timer

**Start a Pomodoro session**:
```bash
tmux send-keys -t work "~/.config/dotfiles/tmux/pomodoro.sh 4 25 5" Enter
```

Arguments:
- `4` – Number of sessions
- `25` – Work duration (minutes)
- `5` – Break duration (minutes)

Features:
- Audio notification (Ringing.mp3)
- Desktop notification via `notify-send`
- Manual status display when invoked directly
- Stop: `~/.config/dotfiles/tmux/pomodoro.sh stop`

### Random Note Picker

Displays a random incomplete task from today's todo file:

```bash
~/.config/dotfiles/tmux/random_note.sh
```

Looks for files matching: `~/Documents/git/scratch/todo_YYMMDD.md`

Output example:
```
⏰ Implement user authentication
```

Used as an explicit helper when you want a task suggestion without adding polling to tmux status.

### Wezterm Music & Background

**Background slideshow**:
- Rotates images in `~/.config/dotfiles/wezterm/bg/` every 5 minutes
- Supports jpg, png, jpeg

**Background music**:
- Randomizes tracks from `~/.config/dotfiles/wezterm/sd/`
- Plays via `mpv` (automatic OS detection)
- Keyboard shortcut: `Ctrl+Shift+P` (to manually play random track)

Configure in `.wezterm.lua`:
```lua
local music_folder = home .. "/dotfiles/wezterm/sd"
local background_folder = home .. "/dotfiles/wezterm/bg"
```

---

## Performance Considerations

### Nvim Startup Time

Typical startup: **< 50ms** (with plugins lazy-loaded)

Benchmark:
```bash
time nvim --startuptime /tmp/startup.log +q
cat /tmp/startup.log | tail -20
```

Optimization tips:
- Remove unused plugins from `nvim/lua/plugins/`
- Check `:Lazy profile` for slow plugin load times
- Disable expensive LSP on startup with `lazy = true`

### Tmux Performance

- Session resurrection takes ~2–5 seconds (depending on pane count)
- Plugin CPU overhead: < 1% at idle
- Monitor with: `tmux list-commands | wc -l` (plugin count)

### LSP & Language Servers

Language server memory usage (typical):
| Server | Memory | CPU (idle) |
|--------|--------|-----------|
| clangd | 200–400 MB | < 1% |
| rust-analyzer | 300–500 MB | < 1% |
| pyright | 150–250 MB | < 1% |

Disable unused servers in `nvim/lua/plugins/lsp-config.lua`:
```lua
-- Comment out or remove entries from ensure_installed
```

---

## Security & Secrets Handling

### Git Configuration

**Credential storage** (macOS/Linux):
```bash
git config --global credential.helper osxkeychain  # macOS
git config --global credential.helper cache        # Linux (in-memory)
git config --global credential.helper 'store --file ~/.config/git/credentials'  # Persistent
```

**SSH keys**:
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
ssh-add ~/.ssh/id_ed25519
```

### Sensitive Data in Dotfiles

Never commit:
- API keys, tokens, passwords
- Personal email addresses (use `.gitconfig.save` as template)
- SSH private keys

Use environment variables or `.env` files (Git-ignored):

```bash
# ~/.env.local (add to .gitignore)
export ANTHROPIC_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."

# Load in ~/.zshrc
[ -f ~/.env.local ] && source ~/.env.local
```

### File Permissions

```bash
# Protect config files
chmod 600 ~/.gitconfig
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519

# Protect zsh/bash history
chmod 600 ~/.zsh_history ~/.bash_history
```

---

## Backup & Sync Strategy

### Backup Before Installation

```bash
# Backup existing configs
mkdir -p ~/dotfiles-backup
cp -r ~/.config/nvim ~/dotfiles-backup/
cp ~/.tmux.conf ~/dotfiles-backup/
cp ~/.wezterm.lua ~/dotfiles-backup/
cp ~/.zshrc ~/dotfiles-backup/
cp ~/.gitconfig ~/dotfiles-backup/
```

### Syncing Across Machines

**Option 1: Git remote**:
```bash
cd ~/.config/dotfiles
git remote add origin https://github.com/YOUR_USERNAME/dotfiles.git
git push origin main
```

**Option 2: Rsync** (over SSH):
```bash
rsync -avz ~/.config/dotfiles user@remote-machine:~/.config/
```

**Option 3: Stow** (symlink management):
```bash
brew install stow  # macOS
stow nvim tmux wezterm zsh bash git
```

### Restore on New Machine

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles

# Symlink all configs
for dir in nvim tmux wezterm zsh bash git; do
  ln -s ~/.config/dotfiles/$dir ~/.config/ 2>/dev/null || true
done

nvim +Lazy sync
```

---

## Custom Scripts & Tools

### Pomodoro Script Analysis

**File**: `tmux/pomodoro.sh`

Purpose: Tabletop productivity timer with tmux status integration

Logic:
1. Accepts 3 arguments: sessions, work_minutes, break_minutes
2. Stores state in `~/.cache/pomo.json` (JSON for portability)
3. Plays audio on interval completion (`Ringing.mp3`)
4. Integrates with tmux status bar (displays progress)
5. Can be stopped with `pomodoro.sh stop`

Usage:
```bash
./pomodoro.sh 4 25 5   # 4 sessions of 25min work, 5min break
./pomodoro.sh stop     # Stop timer
```

### Random Note Script Analysis

**File**: `tmux/random_note.sh`

Purpose: Suggest a random incomplete task from daily todo files

Logic:
1. Finds latest `todo_YYMMDD.md` file
2. Parses unchecked tasks: `- [ ] Task name`
3. Randomly selects one
4. Formats for tmux status display

Output format:
```
⏰ Task name
```

Use case: Display in tmux bottom status bar for context-switching inspiration

---

## Troubleshooting

### Nvim Issues

**Plugins not loading**:
```bash
# Clear lazy.nvim cache
rm -rf ~/.local/share/nvim/lazy
nvim +Lazy sync
```

**LSP not starting**:
```bash
# Check Mason installed servers
:MasonInstall
# or manually install
:MasonInstall clangd
```

**Treesitter parser errors**:
```bash
# Reinstall all parsers
:TSUpdate
```

### Tmux Issues

**Plugins not loading**:
```bash
# Remove plugin cache
rm -rf ~/.tmux/plugins/tpm/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source-file ~/.tmux.conf
# Inside tmux: Ctrl+A I
```

**Keybindings not working**:
```bash
# Reload config without restarting
Ctrl+A : source-file ~/.tmux.conf
# or
Ctrl+R (custom binding)
```

### Wezterm Issues

**Background image not showing**:
- Check path in `.wezterm.lua` (should resolve `$HOME`)
- Verify image format: jpg/png/jpeg
- Check file permissions: `ls -la ~/dotfiles/wezterm/bg/`

**Copy/paste not working**:
- Install clipboard tools: `wl-clipboard` (Wayland) or `xclip` (X11)
- Verify: `wl-paste --version` or `xclip -version`

**Audio not playing**:
- Install `mpv`: `brew install mpv` (macOS) or `sudo apt install mpv` (Linux)
- Verify: `mpv --version`
- Check audio device: `pactl list short sinks` (Linux)

### Shell Issues

**Zsh history not saving**:
```bash
# Add to ~/.zshrc
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
```

**Aliases not working after symlink**:
```bash
# Source manually
source ~/.zshrc
# or restart terminal
```

---

## FAQ

**Q: Can I use this on Windows?**
A: Partially. Use WSL2 (Windows Subsystem for Linux) with Ubuntu. Wezterm is available on Windows but tmux/nvim require WSL.

**Q: What's the performance impact of all these plugins?**
A: Nvim startup: ~40–60ms. During editing, CPU overhead is < 1% at idle (LSP may spike to 5–10% during active linting). Tmux adds < 1% CPU.

**Q: How do I disable a plugin I don't need?**
A: Delete or rename the file in `nvim/lua/plugins/` (e.g., `commenting.lua.bak`). Lazy.nvim will skip it.

**Q: Can I use this as a team standard?**
A: Yes. Fork the repo, customize for your team, and distribute the clone link. Consider adding a `team-config.lua` override system.

**Q: How do I backup my session before updating?**
A: Tmux sessions auto-backup every 15 minutes. Manual backup: `Ctrl+A C-s`. Before major updates, run `git stash` in the dotfiles repo.

**Q: Does this support remote SSH sessions?**
A: Yes. SSH into a machine with tmux/nvim installed, or use tmux on local machine to connect to remote shell. Consider using `tmux-resurrect` to save session state before disconnecting.

**Q: How do I integrate with CI/CD (GitHub Actions, etc.)?**
A: Use this setup locally for development. For CI, create a minimal Docker image with core tools (nvim, tmux, node) and exclude GUI-specific configs.

---

## Roadmap

- [ ] Add `telescope-live-grep-raw` for advanced search patterns
- [ ] Integrate DAP debugging for additional languages (Go, Node.js)
- [ ] Add `nvim-dap-virtual-text` configuration refinement
- [ ] Implement keyboard-driven git workflow documentation
- [ ] Add per-project `.nvim-local.lua` support for workspace-specific settings
- [ ] Create bootstrap script for one-command setup
- [ ] Add Docker/Podman integration examples
- [ ] Document performance profiling workflow
- [ ] Add Lua test examples (busted, plenary)
- [ ] Expand terminal emulator comparison (kitty, alacritty alternatives)

---

## License

MIT © 2024–present

Permission granted to use, modify, and distribute these dotfiles for personal, educational, and commercial purposes.

See LICENSE file for details.

---

## Credits & Inspiration

**Tools & Communities**:
- [Neovim](https://neovim.io/) – Hyperextensible Vim-based editor
- [Lazy.nvim](https://github.com/folke/lazy.nvim) – Fast plugin manager
- [Tmux](https://github.com/tmux/tmux) – Terminal multiplexer
- [Catppuccin](https://catppuccin.com/) – Soothing color palette
- [Wezterm](https://wezfurlong.org/wezterm/) – GPU-accelerated terminal
- [Mason.nvim](https://github.com/williamboman/mason.nvim) – Language server installer
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) – Fuzzy finder ecosystem
- [Tim Pope](https://github.com/tpope) – Vim plugins pioneer
- [nvim-community](https://github.com/nvim-community) – Plugin standardization

**Special Thanks**:
- The Neovim community for excellent documentation and examples
- Tmux plugin authors for tmux-resurrect, vim-tmux-navigator, and more
- Open-source maintainers who make this ecosystem possible

---

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/Dyu20705/dotfiles/issues)
- **Neovim Help**: `:help` in Nvim or [neovim.io/doc](https://neovim.io/doc/user/)
- **Tmux Manual**: `man tmux` or [tmux GitHub](https://github.com/tmux/tmux/wiki)
- **Community**: [r/neovim](https://reddit.com/r/neovim), [Discord](https://discord.gg/neovim)

---

**Last Updated**: May 2026  
**Maintainer**: Dyu20705

Happy coding! 🚀
