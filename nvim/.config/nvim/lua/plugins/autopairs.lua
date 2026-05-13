-- Tự động đóng cặp ngoặc, nháy; tôn trọng Tree-sitter và LSP
return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  opts = {
    check_ts = true,         -- dùng Tree-sitter để tránh thêm cặp trong string, comment
    disable_filetype = { 'TelescopePrompt' },
    fast_wrap = {
      map = '<M-e>',        -- bọc vùng chọn bằng ngoặc
      chars = { '{', '[', '(', '"', "'" },
      pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], '%s+', ''),
      end_key = '$',
      keys = 'qwertyuiopzxcvbnmasdfghjkl',
      check_comma = true,
      highlight = 'Search',
      highlight_grey = 'Comment',
    },
  },
}
