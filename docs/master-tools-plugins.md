# Master Tools & Plugins

This document consolidates the repo's recommendations for tools, plugins, and workflow optimization. It replaces the separate recommendation/checklist notes that used to live in `docs/`.

## Goal

Keep the setup aligned with a system-infra engineer workflow:

- fast terminal access
- strong session and window orchestration
- low ambiguity at runtime
- useful review, motion, test, and docs tooling
- minimal UI chrome unless it reduces friction

## Current Stack Already Covers

The current stack already handles the fundamentals well, so new additions should fill a real gap rather than duplicate capability.

- WezTerm for a deterministic terminal frontend
- tmux for sessions, panes, remote workflows, and orchestration
- Neovim for editing, LSP, formatting, linting, tests, and debugging
- Telescope, Neo-tree, Gitsigns, Neotest, Trouble, and DAP for core editor workflows
- Shell tooling for navigation, search, and automation

That means the next tools should improve review, motion, task execution, documentation, or workflow visibility.

## High-Value GitHub Tools

### 1. `sindrets/diffview.nvim`

Best for git review.

Why it is worth it:

- gives a clean, focused diff UI inside Neovim
- useful for config review, infra changes, and multi-file patch inspection
- complements `gitsigns` and `neogit` instead of replacing them

My take:

- this is the best first add if you review changes often

### 2. `folke/flash.nvim`

Best for motion.

Why it is worth it:

- fast jumping inside long config or code files
- reduces repeated search motions
- useful when reading YAML, Lua, shell, Terraform, or markdown

My take:

- a strong productivity upgrade with low conceptual overhead

### 3. `j-hui/fidget.nvim`

Best for LSP visibility.

Why it is worth it:

- surfaces background language-server work in a clean way
- helpful in large workspaces or on slower machines
- makes long-running LSP work less opaque

My take:

- not essential, but practical if you want better progress visibility

### 4. `stevearc/overseer.nvim`

Best for task orchestration inside Neovim.

Why it is worth it:

- useful for build, test, lint, and ad-hoc command workflows
- fits infra work where tasks are often command-driven
- can reduce terminal hopping for repeatable commands

My take:

- add it only if you actually run many commands from Neovim
- if tmux remains the canonical task layer, keep this optional

### 5. `MeanderingProgrammer/render-markdown.nvim`

Best for docs and notes.

Why it is worth it:

- makes markdown and technical notes easier to read
- useful if you write a lot of docs, RFCs, runbooks, or task notes in Neovim
- improves readability without changing workflow semantics

My take:

- the best docs-oriented addition if markdown is a daily format

### 6. `charmbracelet/vhs`

Best for demos and learning artifacts.

Why it is worth it:

- records terminal sessions as reproducible demos
- useful for documentation, onboarding, and teaching workflows
- fits a systems-oriented workflow better than flashy UI plugins

My take:

- one of the nicest non-editor tools if you document workflows or teach others

### 7. `ThePrimeagen/git-worktree.nvim` or similar worktree helpers

Best when you juggle multiple branches or parallel tasks.

Why it is worth it:

- makes worktree-based workflows easier to manage
- useful for infra work where one branch per task or incident is common

My take:

- useful if you already use git worktrees regularly
- otherwise not worth adding yet

## Good, But Optional

### `folke/snacks.nvim`

Why it is interesting:

- polished utility suite
- can replace a handful of smaller helper plugins
- visually modern and widely discussed

Why to be careful:

- it can become a grab bag if too much is enabled
- if you already have working equivalents, it is easy to duplicate functionality

My take:

- worth watching, but do not rush to adopt it unless you want consolidation

### `folke/noice.nvim`

Why it is interesting:

- makes Neovim feel more refined
- can improve noisy command output and LSP messages

Why to be careful:

- it is mostly presentation, not core productivity
- if you value minimalism and debuggability, keep it optional

My take:

- nice to try, but lower priority than review, motion, task, and docs tools

### Language-specific `neotest` adapters

Examples:

- `nvim-neotest/neotest-rust`
- `nvim-neotest/neotest-python`
- `nvim-neotest/neotest-go`
- `nvim-neotest/neotest-jest`

Why they are interesting:

- they make the existing `neotest` workflow actually pay off per language
- they improve the red/green/debug loop in-editor

My take:

- add only for languages you actively test in Neovim
- do not install adapters for languages you rarely touch

### `telescope-fzf-native.nvim`

Why it is interesting:

- improves Telescope sorting/filtering speed
- pairs well with a search-heavy workflow

My take:

- this is a performance add-on, not a workflow add-on
- keep it if build friction is acceptable on all target machines

## Workflow Platform Tools

### Aerospace

Use it if you work on macOS regularly and want keyboard-driven window management.

Why it is useful:

- makes terminal, browser, and editor layouts reproducible
- pairs well with tmux because tmux manages sessions/panes while Aerospace manages app windows
- reduces mouse-driven context switching

What to keep simple:

- deterministic workspace naming
- app-to-space rules for WezTerm, browser, and editor
- simple keybindings for move, resize, and focus
- no fancy auto-layout logic that hides state

### Qutebrowser

Use it if you read docs, dashboards, and admin UIs all day.

Why it is useful:

- keyboard-first web navigation matches the rest of the stack
- good for documentation, issue trackers, internal admin UIs, and Kubernetes/cloud dashboards
- keeps browser work in the same productivity model as tmux and Neovim

What to prioritize:

- sensible keymaps for tab/window/session switching
- clipboard integration that behaves well with tmux and the OS clipboard
- per-site settings for noisy admin pages
- download/open handling for logs, manifests, and build artifacts

What to avoid:

- too many custom bindings
- aggressive privacy tweaks that break internal tooling
- browser automation glue unless you truly need it

## Docker & Container Workflow

The repo now has a dedicated `docker-compose.yaml` for LazyDocker.

Recommended usage:

```bash
docker compose run --rm lazydocker
```

That service should:

- mount `/var/run/docker.sock`
- persist config under `~/.config/jesseduffield/lazydocker`
- keep `stdin_open` and `tty` enabled for interactive use

## What I Would Not Add Yet

- another file explorer when `neo-tree` already works
- another terminal emulator as a primary daily driver
- another statusline/theme stack
- dashboard or start-screen plugins that add startup noise
- editor plugins that only make the UI denser without reducing friction
- browser automation unless there is a clear workflow need

## Optimization Rules

These are the constraints that keep the stack stable.

1. Prefer review and motion improvements before adding UI polish.
2. Keep lazy-loading explicit; avoid auto-install or auto-update side effects during editing.
3. Avoid shell-outs in hot paths unless the result is cached or time-bounded.
4. Prefer native or deterministic implementations over plugin-driven status widgets.
5. Keep remote and SSH workflows predictable and clipboard-safe.
6. Treat new tools as replacements or gap-fillers, not as additive chrome.

## Checklist Before Adding a Tool or Plugin

Answer these questions first:

- What concrete problem does this solve?
- What does it replace, or is it duplicating?
- Does it slow startup or add runtime complexity?
- Does it improve review, debug, test, docs, or navigation?
- If it were removed, would the workflow actually get worse?

If the answers are unclear, do not add it yet.

## Suggested Priority Order

If only a few additions are made, use this order:

1. `sindrets/diffview.nvim`
2. `folke/flash.nvim`
3. `MeanderingProgrammer/render-markdown.nvim`
4. language-specific `neotest` adapters for the languages you actually test
5. `charmbracelet/vhs`
6. `j-hui/fidget.nvim`
7. `stevearc/overseer.nvim` if you want in-editor tasks
8. `ThePrimeagen/git-worktree.nvim` if you already use worktrees regularly

## Bottom Line

For this workflow, the best additions are review, motion, docs, and task tools.

If you want the shortest shortlist:

- `diffview.nvim`
- `flash.nvim`
- `render-markdown.nvim`
- `vhs`

Everything else should be added only when it closes a real gap.

## Installation

Quick, minimal installation notes for the recommended tools. These are examples — prefer your distribution's packages or your dotfiles' install system.

- **Neovim (plugins)**: use a plugin manager like `lazy.nvim` or `packer.nvim`. Minimal `lazy.nvim` example (add to your Neovim config):

```lua
-- bootstrap lazy.nvim per its README
require('lazy').setup({
	'sindrets/diffview.nvim',
	'folke/flash.nvim',
	'MeanderingProgrammer/render-markdown.nvim',
	'nvim-neotest/neotest',
	'nvim-neotest/neotest-go',
	'nvim-telescope/telescope-fzf-native.nvim',
})
```

- **tmux**: install via your OS package manager and symlink or copy your tmux config into `~/.tmux.conf` (or use the existing `tmux/` folder). Example:

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install tmux
# Arch
sudo pacman -S tmux
```

- **WezTerm**: install from your OS packages or from the project's releases. On many Linux distros it's available via package managers or the project's install instructions: https://wezfurlong.org/wezterm/.

- **LazyDocker (docker-compose service)**: the repo already includes `docker-compose.yaml`. Run the service interactively:

```bash
docker compose run --rm lazydocker
```

- **General note**: add only the language-specific `neotest` adapters you actively use (for example `neotest-go` for Go). Enable `telescope-fzf-native.nvim` only if building native extensions is acceptable on your machines.

### Example `lazy.nvim` bootstrap (complete)

This snippet boots `lazy.nvim` if missing and configures the suggested plugins. Drop into `~/.config/nvim/init.lua` or `lua/plugins/init.lua` per your layout.

```lua
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		'git', 'clone', '--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
	{ 'sindrets/diffview.nvim' },
	{ 'folke/flash.nvim' },
	{ 'MeanderingProgrammer/render-markdown.nvim' },
	{
		'nvim-neotest/neotest',
		dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
	},
	{ 'nvim-neotest/neotest-go' },
	{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
})
```

### Minimal `neotest` + `neotest-go` example

Add this in your Neovim Lua config to wire `neotest` to the Go adapter and a test runner keymap.

```lua
require('neotest').setup({
	adapters = {
		require('neotest-go')({})
	}
})

vim.keymap.set('n', '<leader>t', function()
	require('neotest').run.run()
end, { noremap = true, silent = true })
```

### `tmux` install and tiny `~/.tmux.conf` example

Install (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install -y tmux
```

Tiny `~/.tmux.conf` to get started (paste to `~/.tmux.conf`):

```text
set -g mouse on
setw -g mode-keys vi
set -g history-limit 10000
```

### WezTerm install note

On Linux, prefer your distro package or the project's releases. For many users, the AppImage or distro package is simplest — see https://wezfurlong.org/wezterm/ for platform-specific instructions.

---

If you want, I can also create a `lua/plugins.lua` file in the repo with this `lazy.nvim` snippet, and add a small `neovim/README.md` showing how to enable the `neotest` adapter. Which would you prefer?
