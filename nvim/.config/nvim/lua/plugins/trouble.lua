-- Giao diện tập trung cho diagnostics, quickfix, location list
return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = { 'Trouble', 'TroubleToggle' },
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>',  desc = 'Bật/tắt danh sách lỗi' },
    { '<leader>xw', '<cmd>Trouble diagnostics workspace<CR>',desc = 'Lỗi toàn workspace' },
    { '<leader>xd', '<cmd>Trouble diagnostics document<CR>', desc = 'Lỗi file hiện tại' },
    { '<leader>xq', '<cmd>Trouble quickfix<CR>',             desc = 'Danh sách quickfix' },
    { '<leader>xl', '<cmd>Trouble loclist<CR>',              desc = 'Danh sách location' },
  },
  opts = {
    auto_close = true,
    auto_preview = true,
    position = 'bottom',
    height = 10,
  },
}
