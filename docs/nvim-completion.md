# Neovim Completion Audit and Migration

## Current Stack

- Plugin manager: `lazy.nvim`
- Completion engine: `blink.cmp`
- Snippet engine: `LuaSnip`
- LSP integration: `mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`
- Treesitter: `nvim-treesitter`

## Audit Summary

Before this change, the completion path was a thin `nvim-cmp` setup with only `nvim_lsp` and `buffer` sources enabled. The configuration did not wire snippet expansion into the completion engine, did not expose signature help through the completion UI, and did not use a modern ranking/fuzzy pipeline. That left the editor feeling closer to basic LSP completion than an IDE-grade experience.

The upgraded stack now uses `blink.cmp`, which gives a faster popup, built-in documentation handling, ghost text, signature help, better fuzzy ranking, and built-in sources for LSP, path, snippets, and buffer text. LuaSnip remains in place, so existing snippet workflows do not need to be rewritten.

## Missing Components Found In The Old Setup

- No completion docs preview
- No ghost text preview
- No signature help integration in the completion UI
- No path source
- No explicit snippet source in the completion engine
- No modern fuzzy ranking or tie-breaking
- No Lua language server for editing this Neovim config itself
- No LuaLS runtime/library hints for Neovim API completion
- Redundant completion file that duplicated LuaSnip setup without adding behavior

## Recommended Architecture

- `blink.cmp` for insert-mode completion, ranking, docs, ghost text, and signature help
- `LuaSnip` for snippet expansion and custom snippet loading
- `mason-lspconfig` + `nvim-lspconfig` for server lifecycle and LSP wiring
- `treesitter` for syntax-aware UI rendering and better completion visuals
- `lua_ls` configured with Neovim runtime awareness for dotfile authoring

## Why Blink Over nvim-cmp

`blink.cmp` is a significant upgrade here because it is batteries-included rather than source-plug-in driven. It gives built-in support for docs, signature help, ghost text, and fuzzy matching with less glue code. It also supports LuaSnip directly, so the migration does not require replacing your existing snippet engine.

Pros:

- Faster completion UI
- Better built-in fuzzy ranking
- Built-in docs and ghost text
- Built-in signature help
- Built-in path/buffer/snippet/LSP sources
- Cleaner LSP capability wiring on Neovim 0.12

Cons:

- Smaller ecosystem than `nvim-cmp`
- Some advanced `nvim-cmp` source plugins need compatibility layers
- Signature help is still marked experimental upstream

Decision: migrate. The benefits are large enough for this config, and the current setup was underpowered enough that a partial tune-up would not close the gap.

## Migration Plan

1. Replace the old `nvim-cmp` completion module with `blink.cmp`.
2. Keep `LuaSnip` and `friendly-snippets` so existing snippets continue to work.
3. Switch LSP capabilities to `blink.cmp` so auto-imports and richer completion item metadata flow through the servers.
4. Add `lua_ls` for Lua completion and Neovim API awareness.
5. Remove the redundant completion-only LuaSnip file so snippet setup is defined once.
6. Validate startup, LSP attach, and insert-mode completion behavior.

## Backup Plan

- Keep the old completion behavior recoverable in git history.
- Preserve `LuaSnip` and its loaders so snippet definitions are not lost.
- Leave the old `nvim-cmp` dependency list documented here in case a plugin/source needs to be restored later.

## Rollback Plan

If the new stack causes regressions:

1. Revert `lua/plugins/cmp.lua` back to the `nvim-cmp` configuration.
2. Restore the old `cmp-nvim-lsp` capability wiring in `lua/plugins/lsp-config.lua`.
3. Restore the LuaSnip keymaps if you want the old snippet navigation behavior back.
4. Reintroduce the deleted completion helper file if you want the prior module layout.

## Verification Checklist

- Completion popup opens quickly in insert mode
- LSP suggestions appear for supported filetypes
- Snippets expand and navigate correctly
- Signature help is available from the completion UI
- Path and buffer sources are present
- Auto-import suggestions are preserved through LSP capabilities
- Neovim starts without config errors

## Notes For This Repo

- Optimized language coverage now includes Lua, Python, Rust, Zig, and C/C++.
- Lua is the biggest win from the config change because the editor can now complete its own runtime and API surface through `lua_ls`.
- There is no separate game-engine LSP in the current repo, so the completion system treats game files through the same general LSP/snippet pipeline until a dedicated server is added.
