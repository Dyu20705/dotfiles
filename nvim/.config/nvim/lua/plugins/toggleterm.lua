-- Terminal trong Neovim: float, split, tab; dễ dàng bật/tắt
return {
  'akinsho/toggleterm.nvim',
  version = '*',
  keys = {
    { '<C-\\>', '<cmd>ToggleTerm<CR>',                 desc = 'Bật/tắt terminal' },
    { '<leader>tf', '<cmd>ToggleTerm direction=float<CR>',  desc = 'Terminal dạng float' },
    { '<leader>th', '<cmd>ToggleTerm direction=horizontal<CR>', desc = 'Terminal ngang' },
    { '<leader>tv', '<cmd>ToggleTerm direction=vertical<CR>', desc = 'Terminal dọc' },
  },
  opts = {
    size = function(term)
      if term.direction == 'horizontal' then return 15
      elseif term.direction == 'vertical' then return vim.o.columns * 0.4
      end
    end,
    open_mapping = nil, -- ta dùng keymaps riêng
    hide_numbers = true,
    shade_terminals = false,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    persist_size = false,
    direction = 'float',
    float_opts = {
      border = 'curved',
      width = math.floor(vim.o.columns * 0.8),
      height = math.floor(vim.o.lines * 0.8),
    },
  },
}
