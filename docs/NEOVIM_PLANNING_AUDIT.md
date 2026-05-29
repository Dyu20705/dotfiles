# Neovim Planning Audit

This document is planning only. It does not change Neovim yet.

The current config bootstraps `lazy.nvim` from [nvim/.config/nvim/init.lua](../nvim/.config/nvim/init.lua) and splits most behavior into small plugin modules under [nvim/.config/nvim/lua/plugins](../nvim/.config/nvim/lua/plugins). The stack already covers the important pillars: LSP, completion, treesitter, search, git, tests, and debugging.

## Verified Audit Notes

- `vim-wakatime` was the root startup blocker in the first benchmark. Deferring it to `VeryLazy` reduced startup from tens of seconds to a near-instant boot path.
- The remaining configuration shape looks structurally sound: lazy-loading works, there is no obvious require recursion, and there is no catastrophic Lua parse problem.
- The remaining risk surface is operational, not exploit-driven: bootstrap clone trust, PATH trust for external binaries, and any future Mason/Treesitter auto-install behavior.
- The current next-step priority is to keep startup deterministic by avoiding any plugin that auto-installs, auto-updates, or spawns blocking external work during boot.
- `mason.nvim` and `nvim-lspconfig` were moved off the startup path, and `mason-lspconfig` no longer auto-installs during editing sessions.
- Cold-start measurements after the first round of cleanup showed a real reduction: baseline median was about 59.2 ms, and the working config median was about 47.6 ms.

## Current Architecture

- Bootstrap: `lazy.nvim` is pulled on demand and then loads the `plugins` module set.
- LSP: [lsp-config.lua](../nvim/.config/nvim/lua/plugins/lsp-config.lua) wires `mason.nvim`, `mason-lspconfig.nvim`, and `nvim-lspconfig` with `cmp_nvim_lsp` capabilities.
- Completion: [cmp.lua](../nvim/.config/nvim/lua/plugins/cmp.lua) provides `nvim-cmp`, buffer/path sources, and `LuaSnip`.
- Treesitter: [treesitter.lua](../nvim/.config/nvim/lua/plugins/treesitter.lua) is currently eager and uses `:TSUpdate`.
- Navigation/search: [neotree.lua](../nvim/.config/nvim/lua/plugins/neotree.lua) and [telescope.lua](../nvim/.config/nvim/lua/plugins/telescope.lua) cover file and grep workflows.
- Git/UI helpers: the tree includes `gitsigns`, `neogit`, `lualine`, `which-key`, `catppuccin`, `trouble`, `spectre`, `toggleterm`, `auto-session`, and `waka` (now deferred to `VeryLazy`), plus several small helpers.

## Remove First If Unused

These are the first candidates to delete if they are not earning their keep:

- `waka.nvim` because telemetry is not part of the editor runtime contract and it adds noise without helping editing, review, or debugging.
- `auto-session` if it is reopening state too aggressively or adding surprise file/session mutations.
- `toggleterm` if tmux already owns terminal orchestration and the editor does not need a second terminal manager.
- `mini-indentscope` if visual indentation cues are not changing navigation decisions.
- `auto-tag` if it is not materially improving HTML/XML work.

## Avoid Adding

- More file explorers. `neo-tree` already fills that role.
- More theme/statusline chrome. `catppuccin` and `lualine` should stay minimal or be replaced, not multiplied.
- More motion helpers that overlap with a future `flash.nvim` plan.
- More task runners if tmux remains the canonical task/orchestration layer.
- More dashboards/start screens. They add startup cost and little runtime value.

## Worth Replacing

- `neogit` is worth keeping only if it is the preferred staging/review surface. If review becomes more important than staging, `diffview.nvim` should be the primary review UI and `neogit` should shrink to a smaller staging tool or be removed.
- `toggleterm` is a good replacement candidate for tmux-native terminal workflows, not a must-keep.
- `catppuccin` and `lualine` should be replaced with a minimal, deterministic UI if startup or visual density becomes a problem.

## Startup-Time Risks

- `mason.nvim` and `mason-lspconfig.nvim` can become startup risks if they auto-install during editing sessions.
- `nvim-treesitter` with `:TSUpdate` is a risk if parser builds happen during startup or first open.
- `telescope-fzf-native.nvim` is a build/runtime risk if the native extension is missing or compiled on demand.
- `auto-session` is a risk if it restores state on every open without an explicit opt-in path.
- `neogit` and `gitsigns` are lightweight, but both still touch git state and should stay lazy until a relevant buffer or command is used.
- `waka` was the clearest runtime risk in practice because it introduced startup stalls well beyond normal bounds; it is now deferred, but it still deserves either a hard opt-in policy or removal if telemetry is not required.

## LSP Architecture

Current shape:

- `mason.nvim` installs tools.
- `mason-lspconfig.nvim` ensures servers are present.
- `nvim-lspconfig` enables the servers.
- `cmp-nvim-lsp` provides completion capabilities.

Planning notes:

- Keep the LSP layer explicit and small.
- Prefer server lists that match the actual languages used in this repo.
- Avoid auto-install behavior that can surprise remote or offline sessions.
- Keep keymaps centralized and simple.

## Tree-Sitter Strategy

- Keep tree-sitter parsers for filetypes that actually affect daily editing quality.
- Do not let parser installation or updates happen as an implicit editing-side effect.
- Prefer a small, deterministic parser set over broad coverage.
- If parser maintenance starts to dominate, narrow the filetype list before adding more plugins.

## Completion Architecture

Current shape:

- `nvim-cmp` is the main completion engine.
- `LuaSnip` supplies snippets.
- `cmp-buffer` and `cmp-path` provide low-risk fallback sources.

Planning notes:

- Keep completion sources small and predictable.
- Do not add extra source plugins unless they solve a real workflow gap.
- Avoid completion layers that require background polling or network access.
- Keep the insert-mode path deterministic enough to work cleanly over SSH and in detached tmux.

## UI and Plugin Minimalism

The current UI layer should stay as small as possible:

- `which-key` should remain only if shortcut discovery is actively useful.
- `lualine` should stay lightweight or be replaced by a minimal statusline.
- `catppuccin` should remain purely cosmetic and never become a runtime dependency for core editing.
- `trouble` is useful if diagnostics/navigation is part of the daily loop; otherwise it is a candidate to cut.

The rule is simple: if a plugin mainly changes how Neovim looks but not how work moves, it should be treated as optional.

## Remote and SSH Editing Behavior

- Remote sessions should favor predictability over polish.
- Avoid automatic session restore, background task execution, or editor-startup side effects over SSH.
- Keep terminal integration minimal and rely on tmux for remote workspace orchestration.
- Do not assume clipboard integration is present; remote editing must still work when GUI clipboards are missing.
- If a plugin depends on local filesystem watchers or OS-specific UI assumptions, it should be gated or disabled remotely.

## Deterministic Lazy-Loading Strategy

Target behavior:

- Core editing primitives load immediately.
- Heavy or optional UI plugins load only on the relevant event, command, filetype, or keymap.
- No plugin should auto-install, auto-update, or spawn background work during startup.
- First-run setup must be explicit and separate from the normal edit path.

Suggested policy:

1. Keep always-on: LSP plumbing, completion plumbing, treesitter core, and essential navigation.
2. Lazy-load on demand: review UIs, terminal wrappers, session restore, and UI chrome.
3. Gate remote/offline paths: anything that can talk to the network, build native code, or watch the filesystem.

## Performance Policy

- No plugin should be eager-loaded unless it is part of the core edit loop.
- No plugin should auto-install, auto-update, or restore sessions implicitly during startup.
- UI chrome should load on `VeryLazy` or by explicit command/keymap.
- Filesystem explorers and terminal wrappers should load on command or mapping, not on boot.
- Heavy language tooling should be attached by file event or LSP enablement, not globally.
- Startup target should remain below 80 ms on the common path.

## Short Priority Order

If the next Neovim phase starts, the likely order is:

1. Remove or gate `waka`.
2. Decide whether `auto-session` belongs in a tmux-first workflow.
3. Decide whether `toggleterm` is redundant with tmux.
4. Decide whether `diffview.nvim` should replace most review use of `neogit`.
5. Narrow lazy-loading so only truly necessary pieces stay eager.

## Proposed Commits

1. `perf(nvim): defer session restore and remove treesitter startup updates`
2. `perf(nvim): defer neo-tree and lualine from cold start`
3. `docs(nvim): record startup policy and benchmark results`

## What Not To Do Next

- Do not add more UI plugins before the current stack is trimmed.
- Do not add AI or dashboard layers unless there is a specific workflow contract.
- Do not broaden treesitter or LSP coverage until the existing list is stable.
- Do not change Neovim runtime files yet; this document is the planning gate.