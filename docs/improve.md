Với mục tiêu trở thành system/infra engineer, repo dotfiles nên hướng tới:

* reproducible
* modular
* observable
* scriptable
* fast startup
* keyboard-driven
* debugging-friendly
* automation-first

Cấu trúc hiện tại của bạn còn hơi “flat”. Một repo chuẩn production-grade thường tách:

* config
* scripts
* bootstrap
* OS-specific
* secrets
* docs
* backups
* tooling manifests

---

# Cây dự án dotfiles nên hướng tới

```txt
dotfiles/
├── README.md
├── LICENSE
├── .gitignore
├── install.sh
├── bootstrap.sh
├── Brewfile
├── packages.txt
├── assets/
│   ├── preview.png
│   └── screenshots/
│
├── scripts/
│   ├── setup/
│   ├── backups/
│   ├── diagnostics/
│   ├── sync/
│   ├── git/
│   ├── tmux/
│   └── utils/
│
├── docs/
│   ├── workflow.md
│   ├── keybindings.md
│   ├── troubleshooting.md
│   └── architecture.md
│
├── shell/
│   ├── bash/
│   └── zsh/
│       ├── .zshrc
│       ├── aliases.zsh
│       ├── exports.zsh
│       ├── functions.zsh
│       ├── completion.zsh
│       ├── plugins.zsh
│       ├── prompt.zsh
│       └── paths.zsh
│
├── git/
│   ├── .gitconfig
│   ├── .gitignore_global
│   ├── commits/
│   └── hooks/
│
├── tmux/
│   ├── tmux.conf
│   ├── plugins/
│   ├── themes/
│   └── scripts/
│
├── wezterm/
│   ├── wezterm.lua
│   ├── modules/
│   ├── themes/
│   └── utils/
│
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lua/
│   │   ├── core/
│   │   ├── plugins/
│   │   ├── lsp/
│   │   ├── dap/
│   │   ├── ui/
│   │   ├── utils/
│   │   ├── commands/
│   │   └── autocmds/
│   │
│   ├── after/
│   ├── ftplugin/
│   ├── snippets/
│   └── spell/
│
├── infra/
│   ├── ssh/
│   ├── kubectl/
│   ├── docker/
│   ├── k9s/
│   ├── terraform/
│   ├── ansible/
│   └── tailscale/
│
├── monitoring/
│   ├── btop/
│   ├── fastfetch/
│   ├── htop/
│   └── logs/
│
├── security/
│   ├── gpg/
│   ├── age/
│   ├── ssh/
│   └── secrets.example/
│
└── local/
    ├── machine-specific/
    └── ignored/
```

---

# Bạn nên thêm gì để workflow mạnh hơn

## 1. Shell tooling (rất quan trọng)

Nên thêm:

| Tool     | Mục đích           |
| -------- | ------------------ |
| zoxide   | smarter cd         |
| eza      | thay ls            |
| bat      | thay cat           |
| fd       | thay find          |
| ripgrep  | grep siêu nhanh    |
| fzf      | fuzzy everything   |
| atuin    | shell history mạnh |
| direnv   | auto env           |
| starship | prompt             |
| thefuck  | fix command        |
| jq/yq    | xử lý json/yaml    |
| entr     | watch files        |
| delta    | git diff đẹp       |
| just     | task runner        |
| tldr     | docs nhanh         |

---

## 2. Infra/System tools

Rất nên có:

| Tool          | Use case      |
| ------------- | ------------- |
| lazydocker    | docker tui    |
| k9s           | kubernetes    |
| bottom/btop   | monitoring    |
| iotop         | IO debug      |
| strace/ltrace | syscall debug |
| tcpdump       | networking    |
| dig/nslookup  | DNS           |
| ncdu          | disk usage    |
| hyperfine     | benchmark     |
| perf          | profiling     |
| dust          | disk analyzer |
| xh            | HTTP client   |
| doggo         | DNS tool      |
| bandwhich     | bandwidth     |
| lazygit       | git tui       |

---

## 3. Neovim cho system/infra

Bạn nên thêm:

### Core

* telescope
* treesitter
* which-key
* snacks.nvim
* trouble.nvim
* todo-comments
* mini.nvim

### Infra plugins

* dockerfile support
* terraform-ls
* ansible-ls
* yamlls
* helm-ls
* bashls
* nginx-ls

### Debugging

* nvim-dap
* dap-ui
* persistent breakpoints

### Git

* gitsigns
* diffview
* neogit

### Navigation

* harpoon
* flash.nvim
* leap.nvim

### Performance

* lazy.nvim profiling
* startup optimization

---

# Workflow system engineer nên có

## Terminal layout

Tmux:

* pane monitoring
* logs
* editor
* shell
* docs

---

## Git workflow

Nên có:

* aliases
* signed commits
* delta diff
* interactive rebase helpers
* worktree helpers

---

## SSH workflow

Nên setup:

* ssh-agent
* multiplexing
* persistent sockets
* jump hosts
* aliases

---

# Bạn có nên dùng thêm?

## Có.

### Yazi

File manager cực mạnh.

### Zellij

Có thể thử thay tmux.

### Nushell

Rất mạnh cho data pipeline/system scripting.

### Nix/Home Manager

Nếu muốn infra-level reproducible environment.

---

# Prompt cực mạnh cho AI Coding Agent

Prompt này dành cho:

* Claude Code
* OpenAI Codex
* Cursor
* Gemini CLI
* Cline
* Roo Code

# ROLE

You are a senior Linux infrastructure engineer, Neovim architect, shell tooling expert, and production-grade dotfiles maintainer.

Your task is to audit, refactor, optimize, stabilize, and extend my Ubuntu dotfiles repository for a high-performance system/infra engineering workflow.

The repository currently contains configurations for:

* zsh
* bash
* tmux
* wezterm
* neovim
* git

Your goal is to transform the repository into a production-quality, modular, maintainable, reproducible, safe, and performance-optimized developer environment.

---

# PRIMARY OBJECTIVES

1. Improve workflow efficiency
2. Reduce friction in daily terminal usage
3. Optimize startup performance
4. Improve maintainability
5. Improve observability/debugging
6. Improve infrastructure engineering workflows
7. Keep configs stable and low-bug
8. Avoid breaking existing workflows
9. Ensure all changes are production-safe
10. Ensure everything works on real Ubuntu systems

---

# IMPORTANT SAFETY REQUIREMENTS

You MUST follow ALL of these rules:

* NEVER blindly rewrite configs
* NEVER delete configs without backup
* NEVER introduce experimental unstable plugins unless clearly justified
* NEVER add overlapping/redundant tooling
* NEVER break startup flow
* NEVER add plugins with known heavy startup penalties unless lazy-loaded
* NEVER hardcode machine-specific paths
* NEVER remove existing functionality without explanation
* ALWAYS preserve backward compatibility when possible

Before modifying:

* analyze current configs deeply
* understand architecture
* understand dependency relationships
* identify fragile areas
* detect conflicts between plugins/tools

For every modification:

* explain WHY
* explain PERFORMANCE impact
* explain STABILITY impact
* explain SECURITY impact

---

# REQUIRED EXECUTION STRATEGY

Follow this exact order:

1. Audit repository structure
2. Analyze startup bottlenecks
3. Detect duplicated configs
4. Detect anti-patterns
5. Detect outdated plugins
6. Detect dangerous shell patterns
7. Detect slow Neovim plugins
8. Detect tmux conflicts
9. Detect shell startup issues
10. Detect git workflow inefficiencies

THEN:

11. Propose improvements
12. Implement improvements safely
13. Create backups before changes
14. Add rollback capability
15. Validate syntax/config correctness
16. Ensure configs actually work together

---

# ZSH REQUIREMENTS

Optimize for:

* fast startup
* autosuggestions
* fuzzy workflows
* history management
* navigation
* infra productivity

Add/improve:

* fzf integration
* zoxide
* atuin
* bat/eza/fd/ripgrep
* direnv
* smart aliases
* shell completion
* async loading
* prompt optimization
* PATH hygiene

Measure and improve startup performance.

---

# NEOVIM REQUIREMENTS

Optimize Neovim for:

* system programming
* infra engineering
* cloud-native workflows
* terminal-heavy development
* debugging
* large projects

Improve:

* lazy loading
* LSP
* DAP
* Treesitter
* Telescope
* diagnostics
* formatting
* Git integration
* navigation
* performance profiling

Add support for:

* Bash
* C
* Zig
* Lua
* YAML
* TOML
* Dockerfile
* Terraform
* Ansible
* Markdown

Ensure:

* plugins are maintained
* startup is fast
* no duplicated functionality
* no plugin conflicts

---

# TMUX REQUIREMENTS

Improve:

* navigation
* pane/session management
* clipboard integration
* resilience
* workflows
* monitoring layouts

Add:

* TPM
* sensible defaults
* session restore
* vim-tmux navigation
* mouse support
* popup utilities
* fuzzy session switching

---

# WEZTERM REQUIREMENTS

Optimize:

* startup
* keybindings
* multiplexing
* fonts
* shell integration
* performance
* readability

Improve:

* module organization
* appearance consistency
* SSH domains
* workspace support

Avoid:

* unnecessary animations
* unstable hacks
* fragile background logic

---

# GIT REQUIREMENTS

Improve:

* aliases
* diff tooling
* branch workflow
* worktrees
* rebasing
* signed commits
* conflict resolution

Add:

* delta
* useful aliases
* safer defaults
* productivity helpers

---

# INFRA/SYSTEM TOOLING

Recommend and integrate useful tools where appropriate:

* lazygit
* k9s
* lazydocker
* btop
* fastfetch
* jq/yq
* just
* xh
* ncdu
* hyperfine
* dust
* doggo
* bandwhich

Only add tools that genuinely improve workflow.

---

# REPOSITORY STRUCTURE

Refactor repository into a modular architecture.

Add:

* scripts/
* bootstrap/
* backups/
* docs/
* diagnostics/
* local overrides
* secrets examples
* install automation

Ensure:

* clean hierarchy
* maintainability
* reproducibility

---

# INSTALLATION + BOOTSTRAP

Create:

* install scripts
* dependency installation
* symlink management
* backup system
* rollback support
* validation checks

Support:

* Ubuntu primarily
* Debian-compatible systems

---

# VALIDATION

After changes:

* validate shell syntax
* validate Lua syntax
* validate tmux config
* validate WezTerm config
* verify plugin loading
* verify startup performance
* verify no broken references

---

# OUTPUT FORMAT

For every change:

1. explain issue
2. explain reasoning
3. show exact modifications
4. explain rollback path
5. explain performance impact

Generate production-quality code only.

Prefer maintainability and stability over novelty.
