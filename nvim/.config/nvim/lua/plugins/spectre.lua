-- Tìm kiếm và thay thế toàn dự án với giao diện sống động, xem trước
return {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Spectre',
  keys = {
    { '<leader>S', '<cmd>Spectre<CR>', desc = 'Mở Spectre tìm/thay thế' },
    { '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, desc = 'Tìm từ dưới con trỏ' },
  },
  opts = {
    open_cmd = 'vnew',
    live_update = true,
    is_block_ui_break = true,
    mapping = {
      ['toggle_line'] = { map = 'dd', cmd = "<cmd>lua require('spectre').toggle_line()<CR>" },
      ['enter_file']  = { map = '<CR>', cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>" },
      ['send_to_qf']  = { map = '<leader>q', cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>" },
      ['replace_cmd'] = { map = '<leader>rc', cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>" },
    },
  },
}
