-- Định dạng code bất đồng bộ, dùng các formatter ngoài như clang-format, rustfmt, stylua
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    { '<leader>fm', function() require('conform').format({ async = true }) end, desc = 'Định dạng file hiện tại' },
  },
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      rust = { 'rustfmt' },
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      python = { 'black' },
      -- Thêm các ngôn ngữ khác khi cần
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_fallback = true,
    },
    notify_on_error = true,
    default_format_opts = {
      lsp_format = 'fallback',
    },
  },
}
