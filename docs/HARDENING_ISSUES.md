# HARDENING PHASE - CRITICAL ISSUES AUDIT

**Date**: 2026-05-13  
**Phase**: Production Hardening & Conflict Reduction  
**Status**: Issues Identified, Fixes Pending  

## 🔴 CRITICAL ISSUES FOUND

### 1. Empty .zshrc Configuration
**Severity**: CRITICAL  
**Impact**: Fresh Ubuntu user gets bare Zsh with no configuration

```
File: zsh/.zshrc
Status: EMPTY (0 bytes)

Problem:
  - No PATH setup
  - No aliases
  - No functions
  - No prompt configuration
  - No shell options
  - User gets bare shell on first login
```

**Fix Required**: Create functional .zshrc with minimal, safe defaults

---

### 2. Hardcoded Paths in tmux.conf
**Severity**: HIGH  
**Impact**: tmux keybindings fail on fresh Ubuntu

```
File: tmux/.tmux.conf, line 54-56

bind e split-window -h "nvim ~/Documents/git/scratch/notes_\$(date +'%y%m%d%H').md"
bind o split-window -h "nvim ~/Documents/git/scratch/todo_\$(date +'%y%m%d').md"

Problem:
  - ~/Documents/git/scratch/ doesn't exist on fresh Ubuntu
  - 'e' and 'o' keybindings will fail with "directory not found"
  - These are user-specific paths, not portable
```

**Fix Required**: Remove user-specific bindings or make them optional

---

### 3. Wezterm Ambiguity
**Severity**: MEDIUM  
**Impact**: Unclear which config file to use

```
Files present:
  - wezterm/.wezterm.conf (old format?)
  - wezterm/.wezterm.lua (Lua format)

Problem:
  - install.sh only creates symlink to .wezterm.lua
  - .wezterm.conf left unused (confusion)
  - Possible conflicting configurations
```

**Fix Required**: Choose one format, document clearly, remove duplicate

---

### 4. Too Many Heavy Packages
**Severity**: MEDIUM  
**Impact**: Slow first-time bootstrap, unnecessary bloat

```
bootstrap.sh packages (line 192-207):
  - docker.io (700+ MB)
  - docker-compose (100+ MB)
  - kubectl (200+ MB)
  - rustc + cargo (2GB+)
  - clang + lldb + lld (1GB+)

Problem:
  - Most users don't need all these
  - Ubuntu 22.04 apt install rustc can fail or be very slow
  - Increases bootstrap time significantly
  - Not relevant to editor config
```

**Fix Required**: Move to optional/separate install scripts

---

### 5. Too Many Neovim Plugins
**Severity**: MEDIUM  
**Impact**: Slow startup, maintenance burden, conflicts

```
28 plugins installed:
  aerial.lua
  auto-session.lua
  auto-tag.lua
  autopairs.lua
  catppuccin.lua
  cmp.lua
  comment.lua
  completions.lua
  conform.lua
  debugging.lua
  gitsigns.lua
  lsp-config.lua
  lualine.lua
  luasnip.lua
  mini-indentscope.lua
  neogit.lua
  neotest.lua
  neotree.lua
  nvim-lint.lua
  spectre.lua
  surround.lua
  telescope.lua
  toggleterm.lua
  treesitter.lua
  trouble.lua
  undotree.lua
  waka.lua
  which-key.lua

Problems:
  - Startup time bloat
  - Many overlapping features (e.g., neogit + toggleterm git)
  - Not suitable for "dotfiles" repo, more like personal config
  - High maintenance burden
  - May have conflicts or issues
```

**Fix Required**: Audit and reduce to essential core plugins

---

### 6. No Version Requirements
**Severity**: MEDIUM  
**Impact**: May fail on older/newer versions

```
Missing requirements:
  - Neovim: minimum version?
  - Tmux: minimum version?
  - WezTerm: minimum version?
  - Node: minimum version?
  - Python: which version?

Problem:
  - bootstrap.sh installs whatever apt has
  - Could be old versions without required features
  - Could have breaking API changes
```

**Fix Required**: Add version checks to bootstrap

---

### 7. No Dependency Validation
**Severity**: MEDIUM  
**Impact**: Bootstrap fails without clear errors

```
Current flow:
  1. apt install rustc cargo
  2. If it fails: continue anyway
  3. User gets partial setup

Problems:
  - rustc can take 30+ minutes on slow connections
  - cargo may not be in Ubuntu 22.04 standard repo
  - No early detection of system limitations
  - Poor user experience if critical tool fails
```

**Fix Required**: Pre-validate system requirements

---

### 8. tmux Plugin Manager Not Initialized
**Severity**: MEDIUM  
**Impact**: TPM plugins won't load

```
bootstrap.sh has:
  setup_tmux() {
    if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
        log INFO "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm ...
    fi
  }

But:
  - TPM plugins defined in .tmux.conf
  - TPM initialization (~/.tmux/plugins/tpm/tpm) must be sourced
  - .tmux.conf has no explicit TPM plugin listing
```

**Fix Required**: Verify TPM plugins are sourced correctly

---

### 9. No Neovim Plugin Initialization
**Severity**: HIGH  
**Impact**: Neovim first launch hangs or has issues

```
bootstrap.sh has:
  setup_neovim() {
    if [[ ! -d "${HOME}/.local/share/nvim/lazy" ]]; then
        timeout 120 nvim +Lazy sync +q 2>> "${LOG_FILE}"
    fi
  }

Problems:
  - 120 second timeout may not be enough for all plugins
  - First plugin install can have network issues
  - User might interrupt it
  - No retry logic
  - No validation that plugins actually loaded
```

**Fix Required**: Better plugin initialization handling

---

### 10. Shell Default Change
**Severity**: MEDIUM  
**Impact**: Breaks non-interactive shells

```
bootstrap.sh does:
  chsh -s "$(which zsh)"

Problems:
  - Changes default shell permanently
  - May break scripts that expect bash
  - User may not want this
  - Not idempotent if zsh not installed
```

**Fix Required**: Make this optional, add safety checks

---

### 11. Git Config Hardcoded
**Severity**: LOW  
**Impact**: User info won't be correct

```
File: git/.gitconfig

[user]
    name = Dyu200705
    email = duy28092005yh@gmail.com

Problem:
  - This is user-specific (Duy's personal info)
  - Every user gets this config
  - symlink makes git commits under wrong name
```

**Fix Required**: Make git config merge-friendly, not overwrite

---

### 12. No Wezterm Background Setup
**Severity**: LOW  
**Impact**: Background images may not load

```
wezterm/.wezterm.lua references background images
Files in wezterm/bg/ but paths relative to what?
  - Won't work without proper path resolution
  - May cause wezterm to fail on startup
```

**Fix Required**: Fix path handling for background images

---

### 13. Missing LSP Server Installation
**Severity**: MEDIUM  
**Impact**: Neovim LSP won't work

```
bootstrap.sh installs neovim but NOT Mason or LSP servers
  - Mason.nvim needs `~/.local/share/nvim/mason/bin/` populated
  - No lua_ls, pylsp, clangd, etc. installed
  - Neovim health check will report missing LSP

Problem:
  - User gets "LSP not configured" errors
  - Must manually run :MasonInstall
  - Not true "out of box" experience
```

**Fix Required**: Add LSP server installation via Mason

---

## 📊 SUMMARY OF ISSUES

| Category | Count | Severity |
|----------|-------|----------|
| Configuration Issues | 5 | HIGH |
| Package Management | 3 | MEDIUM |
| Missing Features | 2 | MEDIUM |
| Documentation | 1 | LOW |
| **TOTAL** | **11** | **MIXED** |

---

## 🎯 FIX PRIORITY

### Phase 1 - MUST FIX (Blocks usage)
1. ✅ Empty .zshrc → Create functional config
2. ✅ Hardcoded tmux paths → Remove or make optional
3. ✅ Wezterm ambiguity → Choose one format
4. ✅ No LSP initialization → Add Mason setup

### Phase 2 - SHOULD FIX (Improves experience)
5. ⚠️ Too many packages → Split into core + optional
6. ⚠️ Too many plugins → Audit and reduce
7. ⚠️ No version checks → Add validation
8. ⚠️ No dependency validation → Add pre-checks

### Phase 3 - NICE TO FIX (Polish)
9. 💡 Git config hardcoded → Make user-friendly
10. 💡 Shell default change → Make optional
11. 💡 Wezterm background paths → Fix paths

---

## 🚀 IMPLEMENTATION PLAN

### STEP 1: Create Functional .zshrc
- Minimal, safe defaults
- Basic aliases
- Proper PATH setup
- Shell options that make sense

### STEP 2: Fix tmux.conf
- Remove hardcoded ~/Documents paths
- Test all keybindings work
- Verify TPM integration

### STEP 3: Resolve Wezterm Config
- Choose .wezterm.lua as primary
- Document .wezterm.conf deprecation
- Fix background image paths

### STEP 4: Reduce Package Bloat
- Move docker/kubectl/rust to separate install script
- Keep only essential packages
- Document optional packages

### STEP 5: Audit Neovim Plugins
- Test each plugin for conflicts
- Remove duplicates/overlaps
- Document why each is needed
- Reduce to <15 plugins (from 28)

### STEP 6: Add LSP Initialization
- Auto-install critical LSP servers
- Document Mason setup
- Test on fresh Ubuntu

### STEP 7: Add Version Checks
- Neovim 0.9+ minimum
- Tmux 3.0+ minimum
- Python 3.8+ minimum
- Node 16+ minimum

### STEP 8: Improve Error Handling
- Better network failure recovery
- Plugin installation retry logic
- Clear error messages
- Partial install support

---

## ✅ SUCCESS CRITERIA FOR HARDENING

After fixes:
- [ ] Fresh Ubuntu bootstrap completes without errors
- [ ] All symlinks valid and configs work
- [ ] Neovim starts without errors or warnings
- [ ] Tmux starts without errors
- [ ] Zsh starts with proper configuration
- [ ] No hardcoded user-specific paths
- [ ] Package install time < 5 minutes
- [ ] Idempotency verified (2nd run same as 1st)
- [ ] Rollback tested and works
- [ ] Documentation matches reality

---

## 📝 NOTES

- This is infrastructure code, not a hobby config repo
- Treat like production: stability > features
- Fewer plugins = faster startup = happier users
- Version 1.0 should have <15 plugins, not 28
- Focus on core editing experience first

