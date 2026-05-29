-- lua/plugins/which-key.lua
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    plugins = {
      marks = true,
      registers = true,
      spelling = { enabled = true, suggestions = 20 },
      presets = {
        operators = true,
        motions = true,
        text_objects = false,
        windows = false,
        nav = false,
        z = true,
        g = true,
      },
    },
    win = {
      no_overlap = true,
      border = 'rounded',
      title = 'Which Key',
      title_pos = 'center',
      padding = { 1, 2 },
    },
    layout = {
      height = { min = 4, max = 25 },
      width = { min = 20, max = 50 },
      spacing = 3,
      align = 'left',
    },
    show_help = true,
    show_keys = true,
  },
  config = function(_, opts)
    local wk = require('which-key')
    wk.setup(opts)
    wk.add({
      { '<leader>d', group = 'Debug' },
      { '<leader>f', group = 'Tìm kiếm/Telescope' },
      { '<leader>g', group = 'Git' },
      { '<leader>h', group = 'Git hunks' },
      { '<leader>r', group = 'Refactor/LSP' },
      { '<leader>t', group = 'Terminal/Test' },
      { '<leader>w', group = 'Workspace/Session' },
      { '<leader>x', group = 'Diagnostics/Quickfix' },
    })
  end,
}
