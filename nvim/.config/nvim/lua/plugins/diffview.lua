return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  opts = {},
  config = function(_, opts)
    local ok, diffview = pcall(require, 'diffview')
    if ok and diffview.setup then diffview.setup(opts or {}) end
  end,
}
