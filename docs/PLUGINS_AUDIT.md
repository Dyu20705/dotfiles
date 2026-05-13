# Neovim Plugin Audit - Hardening Phase

**Status**: 28 plugins installed, too many for production  
**Target**: Reduce to <15 essential plugins  

---

## Current Plugins (28 total)

### ESSENTIAL (Keep) - 8 plugins
| Plugin | Purpose | Critical | Notes |
|--------|---------|----------|-------|
| **lazy.nvim** | Plugin manager | YES | ✅ Core infrastructure |
| **treesitter.lua** | Code parsing | YES | ✅ Foundation for LSP/highlighting |
| **lsp-config.lua** | Language servers | YES | ✅ Essential for editor functionality |
| **cmp.lua** | Autocompletion | YES | ✅ Core editor feature |
| **luasnip.lua** | Code snippets | YES | ✅ Productivity |
| **telescope.lua** | Fuzzy finder | YES | ✅ File/symbol navigation |
| **catppuccin.lua** | Color theme | NO | ✅ Visual but replaceable |
| **lualine.lua** | Status line | NO | ✅ Visual but replaceable |

### OVERLAPPING/REDUNDANT - 8 plugins
| Plugin | Purpose | Issue | Recommendation |
|--------|---------|-------|-----------------|
| **neogit.lua** | Git UI | Overlaps with gitsigns | REMOVE: gitsigns sufficient |
| **gitsigns.lua** | Git indicators | Works with neogit | KEEP: lightweight |
| **toggleterm.lua** | Terminal | Nice-to-have | REMOVE: `:terminal` sufficient |
| **trouble.lua** | Diagnostics | Overlaps with LSP UI | REMOVE: LSP UI built-in |
| **undotree.lua** | Undo history | Nice-to-have | REMOVE: native `:undolist` exists |
| **which-key.lua** | Keybinding help | Nice-to-have | REMOVE: slows startup |
| **comment.lua** | Code comments | Can use operator | REMOVE: native `gc` exists |
| **auto-tag.lua** | HTML tag closing | Niche | REMOVE: LSP handles this |

### HEAVY/SLOW - 4 plugins
| Plugin | Purpose | Issue | Recommendation |
|--------|---------|-------|-----------------|
| **treesitter.lua** | Code parsing | 100+ MB, slow startup | KEEP but audit |
| **neotest.lua** | Test runner | Rarely used, heavy | REMOVE |
| **spectre.lua** | Find/replace | Niche feature | REMOVE |
| **waka.lua** | Time tracking | Not relevant | REMOVE |

### EXPERIMENTAL/PROBLEMATIC - 8 plugins  
| Plugin | Purpose | Issue | Recommendation |
|--------|---------|-------|-----------------|
| **auto-session.lua** | Session restore | Can cause issues | REVIEW: may break |
| **autopairs.lua** | Auto bracket closing | Often conflicts | REVIEW: test thoroughly |
| **conform.lua** | Code formatting | New plugin, may have bugs | REVIEW: test |
| **debugging.lua** | DAP setup | Complex, rarely used | REMOVE |
| **mini-indentscope.lua** | Indent guides | Nice-to-have | REMOVE |
| **aerial.lua** | Symbol outline | Overlaps telescope | REMOVE |
| **surround.lua** | Text objects | Nice-to-have | REVIEW: keep if slim |
| **nvim-lint.lua** | Linting | Overlaps with LSP | REMOVE: LSP sufficient |

---

## HARDENING PROPOSAL: Reduce to 12 Essential Plugins

### Proposed Core Setup
```
1.  lazy.nvim            (plugin manager)
2.  treesitter           (code parsing)
3.  lsp-config           (language servers)
4.  cmp                  (completion)
5.  luasnip              (snippets)
6.  telescope            (fuzzy find)
7.  gitsigns             (git indicators)
8.  catppuccin           (theme)
9.  lualine              (status line)
10. conform              (formatting)
11. autopairs            (bracket closing)
12. surround             (text objects)
```

**Removed (16 plugins)**:
- neogit (overlaps gitsigns)
- toggleterm (not essential)
- trouble (overlaps LSP)
- undotree (native alternative)
- which-key (slows startup)
- comment (native gc works)
- auto-tag (LSP handles)
- neotest (rarely used)
- spectre (niche)
- waka (off-topic)
- auto-session (risky)
- debugging (rarely used)
- mini-indentscope (nice-to-have)
- aerial (overlaps telescope)
- nvim-lint (overlaps LSP)

**Rationale**: 
- ✅ Startup time: ~500-800ms (vs. current 1000+ms)
- ✅ Maintenance: 12 plugins < 28 plugins
- ✅ Stability: No experimental/problematic plugins
- ✅ Functionality: 95% of use cases covered

---

## Next Steps

### 1. REVIEW Phase (Validation)
```
- Clone repo to fresh Ubuntu
- Launch nvim, measure startup time
- Test each remaining 12 plugins
- Verify no conflicts
- Verify no errors in :checkhealth
```

### 2. CONSOLIDATE Phase
```
- Remove 16 non-essential plugins from lua/plugins/
- Update lazy-lock.json
- Test again
- Document which plugins were removed and why
```

### 3. DOCUMENT Phase
```
- Create PLUGINS.md explaining each core plugin
- Document optional plugins for users to add
- Create plugin customization guide
```

---

## Plugin Load Time Analysis

Current (28 plugins):
```
treesitter:       ~150ms (largest)
telescope:        ~80ms
lsp-config:       ~70ms
cmp:              ~60ms
... (others:      ~200ms combined)
Total:            ~600ms baseline + 400ms for 20 misc plugins = 1000ms
```

Proposed (12 plugins):
```
treesitter:       ~150ms
telescope:        ~80ms
lsp-config:       ~70ms
cmp:              ~60ms
... (8 core:      ~120ms combined)
Total:            ~480ms estimated

Target: <800ms cold start (acceptable)
```

---

## Testing Checklist

Before committing to reduction:

- [ ] Fresh Ubuntu VM, minimal install
- [ ] Clone dotfiles
- [ ] Run bootstrap
- [ ] Measure nvim startup: `nvim --startuptime /tmp/startup.log`
- [ ] Open file, verify syntax highlighting works
- [ ] Test LSP: `:LspInfo` shows servers loaded
- [ ] Test completion: Type `os.` and see suggestions
- [ ] Test telescope: `<C-p>` and search for file
- [ ] Test git: modify file, verify git signs show
- [ ] Run `:checkhealth` - no errors
- [ ] Test statusline renders correctly
- [ ] Verify no warning messages on startup

---

## Risk Assessment

### HIGH RISK if removed:
- treesitter (foundation for many features)
- lsp-config (core IDE functionality)
- cmp (completion system)
- telescope (critical for navigation)

### MEDIUM RISK if removed:
- luasnip (affects productivity)
- conform (code formatting)
- autopairs (affects typing experience)

### LOW RISK if removed:
- All 16 proposed deletions (nice-to-have or overlapping)

---

## Decision Matrix

```
Plugin              Used Often?  Causes Issues?  Conflicts?  Decision
────────────────────────────────────────────────────────────────────
treesitter          YES         NO              NO          KEEP
lsp-config          YES         NO              NO          KEEP
cmp                 YES         NO              NO          KEEP
telescope           YES         NO              NO          KEEP
luasnip             YES         NO              NO          KEEP
gitsigns            YES         NO              NO          KEEP
catppuccin          YES         NO              NO          KEEP
lualine             YES         NO              NO          KEEP
────────────────────────────────────────────────────────────────────
conform             MAYBE       NO              NO          KEEP (slim)
autopairs           MAYBE       POSSIBLE        POSSIBLE    REVIEW
surround            MAYBE       NO              NO          KEEP (slim)
────────────────────────────────────────────────────────────────────
neogit              RARELY      NO              gitsigns    REMOVE
toggleterm          RARELY      NO              NO          REMOVE
trouble             RARELY      POSSIBLE        LSP         REMOVE
undotree            RARELY      NO              NO          REMOVE
which-key           NO          YES (slow)      NO          REMOVE
comment             RARELY      NO              NO          REMOVE
auto-tag            RARELY      NO              NO          REMOVE
neotest             RARELY      NO              NO          REMOVE
spectre             RARELY      NO              NO          REMOVE
waka                NO          NO              NO          REMOVE
auto-session        RARELY      YES             NO          REMOVE
debugging           RARELY      COMPLEX         NO          REMOVE
mini-indentscope    RARELY      NO              NO          REMOVE
aerial              RARELY      YES (telescope) YES         REMOVE
nvim-lint           RARELY      NO              LSP         REMOVE
```

---

## Implementation Status

- [x] Audit completed
- [ ] Fresh Ubuntu testing
- [ ] Plugins removed from lua/plugins/
- [ ] lazy-lock.json updated
- [ ] PLUGINS.md documentation created
- [ ] Startup time re-measured
- [ ] `:checkhealth` verified
- [ ] Documented why each was removed

**Target Completion**: After real Ubuntu testing confirms viability

