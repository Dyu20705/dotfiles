-- Chạy test thông minh: test gần nhất, file, suite; output dạng danh sách
return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    -- adapters do người dùng tự thêm (ví dụ: neotest-rust, neotest-cpp)
  },
  cmd = 'Neotest',
  keys = {
    { '<leader>tn', function() require('neotest').run.run() end,             desc = 'Chạy test gần nhất' },
    { '<leader>tf', function() require('neotest').run.run(vim.fn.expand('%')) end, desc = 'Chạy test file' },
    { '<leader>ts', function() require('neotest').run.run(vim.loop.cwd()) end, desc = 'Chạy cả suite' },
    { '<leader>to', '<cmd>Neotest output<CR>',                               desc = 'Xem output test' },
    { '<leader>tp', '<cmd>Neotest summary<CR>',                              desc = 'Tóm tắt test' },
  },
  opts = {
    adapters = {
      -- require('neotest-rust'),   -- yêu cầu cài đặt adapter trước
      -- require('neotest-cpp'),
    },
    status = { virtual_text = true },
    output = { open_on_run = true },
  },
}
