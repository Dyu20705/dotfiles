-- Toán tử yank-surround, change-surround, delete-surround
return {
  'kylechui/nvim-surround',
  version = '*',
  event = 'VeryLazy',
  keys = {
    { 'ys',  desc = 'Thêm surround', mode = 'n' },
    { 'yS',  desc = 'Thêm surround (dòng)', mode = 'n' },
    { 'yss', desc = 'Surround cả dòng', mode = 'n' },
    { 'ySS', desc = 'Surround cả dòng (dòng)', mode = 'n' },
    { 'S',   desc = 'Thêm surround (visual)', mode = 'x' },
    { 'gS',  desc = 'Thêm surround dòng (visual)', mode = 'x' },
    { 'ds',  desc = 'Xoá surround', mode = 'n' },
    { 'cs',  desc = 'Đổi surround', mode = 'n' },
  },
  config = function()
      require('nvim-surround').setup({

      })
  end,
}
