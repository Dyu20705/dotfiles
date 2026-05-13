# Architecture & Design

## Overview

This dotfiles repository is designed as a **production-grade, modular system** for infrastructure engineers and advanced terminal users.

```
dotfiles/
├── Configuration Modules     (nvim/, tmux/, wezterm/, shell/, git/)
├── Automation & Scripts      (scripts/)
├── Documentation            (docs/)
├── Infrastructure Tools     (infra/, monitoring/, security/)
└── Local Customization      (local/)
```

## Design Principles

### 1. Reproducibility
- All dependencies are version-pinned (lockfiles, package lists)
- Declarative configuration (no manual UI clicks)
- Works identically across machines
- Git-tracked (with .gitignore for secrets/local)

### 2. Modularity
- Each tool is independent (can remove without breaking others)
- Clear directory separation by concern
- No overlapping functionality
- Lazy-loading to minimize startup impact

### 3. Observability
- Built-in diagnostics scripts
- Performance profiling tools
- Health check automation
- Detailed documentation for debugging

### 4. Scriptability
- Everything is programmatically configurable
- Bootstrap automation
- Install scripts for each component
- CI/CD ready

### 5. Performance
- Shell startup: < 100ms
- Neovim startup: < 50ms (without plugins)
- Lazy-loading for LSPs and plugins
- Async loading for expensive operations

### 6. Keyboard-Driven
- Vim-based navigation throughout
- No mouse dependency (except where necessary)
- Consistent keybindings across tools
- Discoverable via `which-key`

### 7. Debugging-Friendly
- System tracing tools (strace, perf)
- Network debugging (tcpdump, dig, xh)
- Profiling support
- Comprehensive logging

### 8. Automation-First
- Infrastructure-as-code principles
- Declarative package management
- Script-based provisioning
- Configuration as code

## Component Architecture

### Shell (Fast & Modular)

```
shell/
├── bash/
│   └── .bashrc           # Shared bash config
└── zsh/
    ├── .zshrc            # Main entry point (sources modules)
    ├── exports.zsh       # Environment variables (lazy)
    ├── aliases.zsh       # Command aliases (instant)
    ├── functions.zsh     # Shell functions (lazy)
    ├── completion.zsh    # Completions (async)
    ├── plugins.zsh       # Plugin manager
    ├── prompt.zsh        # Starship init (fast)
    └── paths.zsh         # PATH configuration
```

**Startup Flow:**
1. `.zshrc` sources modules in order
2. Instant modules (aliases) load synchronously
3. Expensive modules (completion, functions) load asynchronously
4. Prompt initializes Starship (minimal overhead)

**Performance Target:** < 100ms total startup

### Neovim (LSP/DAP IDE)

```
nvim/
├── init.lua              # Bootstrap + Lazy.nvim setup
├── lazy-lock.json        # Dependency lockfile
└── lua/
    ├── core/             # Core settings
    │   ├── options.lua   # vim.opt settings
    │   ├── keymaps.lua   # Default keybindings
    │   └── autocmds.lua  # Autocommands
    ├── plugins/          # Plugin specifications (28 plugins)
    │   ├── lsp/          # LSP plugins
    │   ├── dap/          # Debug plugins
    │   ├── ui/           # UI enhancements
    │   ├── nav/          # Navigation
    │   └── productivity/ # Productivity plugins
    ├── lsp/              # LSP configuration
    ├── dap/              # DAP configuration
    ├── ui/               # UI tweaks
    └── utils/            # Helper functions
```

**Plugin Loading Strategy:**
- Core plugins: `event = "VeryLazy"` (deferred)
- LSP plugins: `event = "BufRead"` (on file open)
- Optional plugins: Explicitly lazy with conditions

**Performance Target:** < 50ms startup, < 100ms first edit

### Tmux (Multiplexing)

```
tmux/
├── tmux.conf             # Main configuration
├── plugins/              # TPM plugins (managed by TPM)
├── themes/               # Theme configurations
├── scripts/              # Helper scripts
└── Ringing.mp3           # Notification sound
```

**Architecture:**
- TPM manages plugins automatically
- Vim-like keybindings throughout
- Session resurrection via tmux-resurrect/continuum
- Mouse support with sensible defaults

### Wezterm (Terminal)

```
wezterm/
├── wezterm.lua           # Main configuration
├── modules/              # Lua modules
│   ├── appearance.lua    # Colors, fonts
│   └── keybinds.lua      # Key mappings
├── themes/               # Color schemes
├── bg/                   # Backgrounds (git-ignored)
└── sd/                   # Audio files (git-ignored)
```

**Features:**
- GPU-accelerated rendering
- Tab/workspace management
- SSH domain support
- Lua scripting for customization

### Scripts (Automation)

```
scripts/
├── setup/                # Installation scripts
│   ├── install-nvim.sh
│   ├── install-lsp.sh
│   ├── install-tmux.sh
│   └── install-tools.sh
├── backups/              # Backup/restore
│   ├── backup-config.sh
│   └── restore-config.sh
├── diagnostics/          # Health checks
│   ├── check-startup.sh
│   ├── check-lsp.sh
│   └── profile-nvim.sh
├── sync/                 # Machine sync
├── git/                  # Git helpers
└── utils/                # General utilities
```

**Philosophy:** Scripts are idempotent and well-documented.

### Infrastructure Tools

```
infra/
├── ssh/                  # SSH config management
├── kubectl/              # Kubernetes config
├── docker/               # Docker config
├── k9s/                  # K9s UI config
├── terraform/            # Terraform config
├── ansible/              # Ansible config
└── tailscale/            # Tailscale config
```

**Integration:** Each tool has a section in shell config (exports/aliases).

### Monitoring & Observability

```
monitoring/
├── btop/                 # System monitor config
├── fastfetch/            # System info
├── htop/                 # Process monitor
└── logs/                 # Log viewer config
```

### Security

```
security/
├── gpg/                  # GPG config
├── age/                  # Age encryption
├── ssh/                  # SSH config (git-ignored)
└── secrets.example/      # Secrets template
```

### Local Customization

```
local/
├── machine-specific.zsh  # Local zsh overrides (git-ignored)
└── ignored/              # Local files (git-ignored)
```

**Philosophy:** Never modify tracked files for local customization.

## Data Flow

### Shell Startup
```
zshrc
  ├─ exports.zsh         (fast, immediate)
  ├─ aliases.zsh         (fast, immediate)
  ├─ paths.zsh           (fast, immediate)
  ├─ prompt.zsh          (starship init)
  └─ [async] remaining modules
      ├─ functions.zsh
      ├─ completion.zsh
      ├─ plugins.zsh
      └─ local/machine-specific.zsh
```

### Neovim Startup
```
init.lua
  ├─ Lazy.nvim bootstrap
  ├─ Core settings
  ├─ Load lazy plugins
  │   ├─ UI plugins
  │   ├─ Navigation plugins
  │   ├─ LSP (deferred until BufRead)
  │   └─ DAP (deferred)
  ├─ Load LSP on BufRead
  └─ init.local.lua (if exists)
```

### Tmux Session
```
tmux.conf
  ├─ Basic settings
  ├─ Keybindings
  ├─ TPM plugins
  └─ Theme settings
  
On attach:
  └─ tmux-resurrect restores session
  └─ vim-tmux-navigator enables H/J/K/L
```

## Git Strategy

### Version Control
- Everything is version-controlled except:
  - `local/` (machine-specific)
  - `security/ssh/` (SSH keys)
  - `wezterm/bg/` and `wezterm/sd/` (media)
  - `.cache/`, `.swp`, etc.

### Branching Model
- `main` – Production-ready configs
- `dev` – Testing new plugins/configs
- Feature branches for major changes

### Commit Strategy
- Meaningful commit messages
- One concern per commit
- Easy to bisect/revert if needed

## Dependency Management

### Package Manager Dependencies
- Tracked in `packages.txt` (Debian/Ubuntu)
- Tracked in `Brewfile` (macOS)
- Install via `scripts/setup/install-tools.sh`

### Cargo/NPM Dependencies
- Install via scripts (see bootstrap)
- Lockfiles ensure reproducibility

### Neovim Plugin Management
- Lazy.nvim for fast, lazy-loading plugin management
- `lazy-lock.json` pins plugin versions
- Update via `:Lazy update` in Neovim

### Language Server Management
- Mason.nvim auto-installs LSPs
- `ensure_installed` in `nvim/lua/lsp/mason.lua`
- Update via `:MasonUpdate` or `nvim +MasonUpdate +q`

## Performance Optimization

### Shell Startup
- Lazy-load expensive functions
- Async load completions
- Minimal module count
- No unnecessary exports

### Neovim Startup
- Lazy-load plugins via Lazy.nvim
- Defer LSP loading until BufRead
- DAP loads only when needed
- Keep init.lua minimal

### Tmux Sessions
- Save/restore sessions (tmux-continuum)
- Avoid spawning unnecessary shells
- Use multiplexing efficiently

## Security Considerations

### Secrets Management
- Never commit secrets to Git
- Use `.gitignore` for sensitive files
- SSH keys in `security/ssh/` (git-ignored)
- Environment variables for API keys

### GPG Integration
- Sign commits (configured in .gitconfig)
- GPG config in `security/gpg/`
- Age encryption support for sensitive data

### SSH Hardening
- SSH config management
- Key rotation support
- Agent multiplexing

## Extensibility

### Adding New Plugins
1. Create file in `nvim/lua/plugins/plugin-name.lua`
2. Lazy.nvim auto-discovers it
3. Lazy will load it according to spec

### Adding New Tools
1. Create subdirectory in `infra/` or appropriate category
2. Add shell aliases in `shell/zsh/aliases.zsh`
3. Document in `docs/`

### Machine-Specific Config
1. Create `local/machine-specific.zsh`
2. Export vars, aliases, overrides
3. Git-ignored automatically

## Testing & Validation

### Startup Testing
```bash
make diagnostics
# Or manually:
bash scripts/diagnostics/check-startup.sh
bash scripts/diagnostics/check-lsp.sh
```

### Syntax Validation
```bash
nvim +checkhealth nvim.lsp
zsh -n ~/.zshrc
tmux source-file -q ~/.tmux.conf
```

### CI/CD Integration
- Scripts are CI/CD compatible
- Idempotent installers
- Health checks for validation

## Future Enhancements

- [ ] Automated nix/home-manager integration
- [ ] Container-based environment (Docker)
- [ ] Advanced performance profiling
- [ ] Config templating for team use
- [ ] Backup/restore automation
- [ ] Multi-machine sync via Git
