# Neovim Plugin Audit

## Core startup owners

Core owns editing, navigation, search, LSP, diagnostics, formatting and syntax.
The lock file remains authoritative for exact commits. Treesitter is eager only
because parser-backed highlighting is a baseline requirement; network install is
disabled during startup.

## Extended capability owners

The following plugin groups are retained but gated: terminal, tests, debug UI,
file tree, session restoration, outline, Markdown UI, undo tree, project replace
and broad Git UI. Each group has one capability identifier and no normal-startup
ownership. The canonical contract is checked by `scripts/check-nvim-contract.sh`.

## Keep, move, deprecate

- Keep core: lazy.nvim, Treesitter, Telescope, LSP, Conform, nvim-lint, Trouble.
- Move behind capability: Neo-tree, Neogit, ToggleTerm, Neotest, DAP UI,
  Aerial, Spectre, render-markdown, auto-session and Undotree.
- Deprecate duplicate terminal, tree, test or Git owners rather than adding a
  second default implementation.
