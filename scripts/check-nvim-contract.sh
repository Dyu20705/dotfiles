#!/usr/bin/env bash
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FAILURES=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

contains() {
  local file=$1 pattern=$2
  grep -Eq "$pattern" "$file"
}

not_contains() {
  local file=$1 pattern=$2
  ! grep -Eq "$pattern" "$file"
}

check() {
  local name=$1
  shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

treesitter="$ROOT/nvim/.config/nvim/lua/plugins/treesitter.lua"
treesitter_spec="$ROOT/nvim/tests/treesitter_spec.lua"
lsp="$ROOT/nvim/.config/nvim/lua/plugins/lsp-config.lua"
autotag="$ROOT/nvim/.config/nvim/lua/plugins/auto-tag.lua"
trouble="$ROOT/nvim/.config/nvim/lua/plugins/trouble.lua"
conform="$ROOT/nvim/.config/nvim/lua/plugins/conform.lua"
lint="$ROOT/nvim/.config/nvim/lua/plugins/nvim-lint.lua"
lualine="$ROOT/nvim/.config/nvim/lua/plugins/lualine.lua"
wezterm="$ROOT/wezterm/.wezterm.lua"

check "Treesitter pins the Neovim 0.11-compatible branch" \
  contains "$treesitter" 'branch[[:space:]]*=[[:space:]]*["'\'']master["'\'']'
check "Treesitter is not lazy-loaded" \
  contains "$treesitter" 'lazy[[:space:]]*=[[:space:]]*false'
check "Treesitter does not use VeryLazy" \
  not_contains "$treesitter" 'VeryLazy'
check "Treesitter enables highlighting" \
  contains "$treesitter" 'highlight[[:space:]]*=[[:space:]]*\{'
check "Treesitter disables automatic network installation" \
  contains "$treesitter" 'auto_install[[:space:]]*=[[:space:]]*false'
check "Treesitter tolerates an unavailable plugin during bootstrap" \
  lua "$treesitter_spec" "$treesitter"

for parser in lua vim vimdoc query bash python javascript typescript tsx html css json yaml dockerfile c cpp rust go terraform markdown markdown_inline; do
  check "Treesitter selects parser: $parser" \
    contains "$treesitter" '["'\'']'"$parser"'["'\'']'
done

check "Mason config has no unsupported auto_install option" \
  not_contains "$lsp" 'auto_install'
check "Mason automatic LSP enablement is disabled" \
  contains "$lsp" 'automatic_enable[[:space:]]*=[[:space:]]*false'
check "LSP capabilities are declared in a workload manifest" \
  test -f "$ROOT/nvim/.config/nvim/lua/config/languages.lua"

check "nvim-ts-autotag calls its supported setup API" \
  contains "$autotag" 'nvim-ts-autotag.*setup|nvim_ts_autotag.*setup'

check "Trouble uses the qflist mode" \
  contains "$trouble" 'Trouble qflist toggle'
check "Trouble has a current-buffer diagnostics mapping" \
  contains "$trouble" 'filter\.buf=0'
check "Trouble uses the current win option" \
  contains "$trouble" 'win[[:space:]]*=[[:space:]]*\{'
check "Trouble does not use stale quickfix command form" \
  not_contains "$trouble" 'Trouble quickfix'
check "Trouble does not use stale workspace/document command forms" \
  not_contains "$trouble" 'diagnostics (workspace|document)'

check "Conform uses lsp_format" \
  contains "$conform" 'lsp_format[[:space:]]*=[[:space:]]*["'\'']fallback["'\'']'
check "Conform has no stale lsp_fallback option" \
  not_contains "$conform" 'lsp_fallback'
check "Lint is not triggered on TextChanged" \
  not_contains "$lint" 'TextChanged'

check "Lualine uses Catppuccin's supported theme helper" \
  contains "$lualine" 'catppuccin\.utils\.lualine'
check "Lualine does not request the removed built-in Catppuccin theme" \
  not_contains "$lualine" 'theme[[:space:]]*=[[:space:]]*["'\'']catppuccin["'\'']'

check "WezTerm has no unmodified function-key media aliases" \
  not_contains "$wezterm" 'mods[[:space:]]*=[[:space:]]*["'\'']NONE["'\'']'

declare -A extended_plugins=(
  [toggleterm.lua]=terminal
  [neotest.lua]=test
  [debugging.lua]=debug
  [neotree.lua]=filetree
  [aerial.lua]=outline
  [neogit.lua]=git_ui
  [auto-session.lua]=session
  [undotree.lua]=undo_tree
  [spectre.lua]=project_replace
  [render-markdown.lua]=markdown_ui
)

for plugin_file in "${!extended_plugins[@]}"; do
  capability=${extended_plugins[$plugin_file]}
  path="$ROOT/nvim/.config/nvim/lua/plugins/$plugin_file"
  check "$plugin_file is gated by capability $capability" \
    contains "$path" 'capabilities\.enabled\(["'\'']'"$capability"'["'\'']\)'
done

for generated in \
  zsh/.zcompdump \
  tmux/.tmux.conf.backup \
  tmux/.tmux.conf.hardened \
  wezterm/.wezterm.conf; do
  if git -C "$ROOT" ls-files --error-unmatch "$generated" >/dev/null 2>&1; then
    fail "$generated is not tracked"
  else
    pass "$generated is not tracked"
  fi
done

printf '\nNeovim contract result: %d failure(s)\n' "$FAILURES"
[ "$FAILURES" -eq 0 ]
