-- Linting bất đồng bộ khi vào buffer, lưu file hoặc rời insert
return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = {
      lua = { 'luacheck' },
      rust = { 'clippy' },
      c = { 'clangtidy' },
      cpp = { 'clangtidy' },
      python = { 'pylint' },
      -- Bổ sung các linter khác
    }
    -- Tự động chạy lint sau các sự kiện
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave', 'TextChanged' }, {
      pattern = '*',
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
