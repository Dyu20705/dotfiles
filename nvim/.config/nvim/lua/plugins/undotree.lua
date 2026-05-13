-- Cây lịch sử undo: xem, đi đến các nhánh, xem diff
return {
  'mbbill/undotree',
  cmd = 'UndotreeToggle',
  keys = {
    { '<leader>u', '<cmd>UndotreeToggle<CR>', desc = 'Bật/tắt cây undo' },
  },
  config = function()
    vim.g.undotree_WindowLayout = 2         -- layout 2 panel
    vim.g.undotree_SetFocusWhenToggle = 1   -- focus vào cửa sổ undotree khi bật
    vim.g.undotree_DiffAutoOpen = 1         -- tự mở diff khi chọn node
    vim.g.undotree_HelpLine = 0
  end,
}
