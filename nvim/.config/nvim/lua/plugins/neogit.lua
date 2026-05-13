-- Giao diện Git giống Magit, quản lý stage, commit, log, stash
return {
  'NeogitOrg/neogit',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Neogit',
  keys = {
    { '<leader>gg', '<cmd>Neogit<CR>', desc = 'Mở Neogit' },
  },
  opts = {
    kind = 'tab',               -- 'tab', 'floating', 'split'
    disable_signs = false,
    disable_hint = false,
    disable_context_highlighting = false,
    disable_commit_confirmation = false,
    signs = {
      section = { '>', 'v' },
      item = { '>', 'v' },
      hunk = { '', '' },
    },
    integrations = { diffview = false },
  },
}
