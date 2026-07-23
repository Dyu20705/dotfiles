# Neovim

## Purpose

Neovim is the editor, review UI, and debug/test host in this stack.

## Why This Setup Exists

- keep editing, search, review, and debugging in one place
- load plugin features only when they are needed
- make docs and Markdown readable inside the editor itself

## Key Features Actually Enabled

| Feature | Notes |
| --- | --- |
| Plugin manager | `lazy.nvim` bootstrap in `init.lua` |
| Search | `telescope.nvim` with `fzf-native` only when `make` exists |
| Git | `gitsigns.nvim`, `neogit`, `diffview.nvim` |
| Motion | `flash.nvim` |
| Docs | `render-markdown.nvim` for Markdown buffers |
| Tests | `neotest` with explicit adapters |
| Debug | `nvim-dap` stack with DAP UI and virtual text |
| Sessions | `auto-session` save and restore |
| Terminal | `toggleterm.nvim` |
| Trees | `neo-tree`, `aerial`, `trouble`, `undotree` |

## Important Keymaps

| Key | Action |
| --- | --- |
| `Space` | Leader key |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>gg` | Open Neogit |
| `<leader>hs` / `<leader>hr` | Stage or reset hunk |
| `]c` / `[c` | Next or previous hunk |
| `<F5>` / `<F10>` / `<F11>` / `<F12>` | Debug navigation |
| `<leader>tn` / `<leader>tf` / `<leader>ts` | Run tests |
| `<leader>ws` / `<leader>wr` | Save or restore session |
| `<leader>tf` / `<leader>th` / `<leader>tv` | ToggleTerm layouts |
| `<leader>xx` / `<leader>xd` / `<leader>xw` | Trouble diagnostics views |

## Typical Flow

1. Open the target file.
2. Search or jump to the right symbol.
3. Inspect Git changes with Gitsigns or Diffview.
4. Format or refactor.
5. Run tests and then debug if needed.
6. Save the session when you are done.

## Productivity Tips

- learn the `which-key` groups so the keymap stays discoverable
- use Neovim for review when the change is local to the file or patch
- use render-markdown to keep docs readable without changing the source text

## Common Pitfalls

- expecting every plugin to be loaded at startup
- using the editor as a terminal manager instead of tmux
- forgetting that some features only appear in matching filetypes or commands

## Related Tools

- [Git](git.md)
- [tmux](tmux.md)
- [LazyGit](lazygit.md)
