local capabilities = require("config.capabilities")
if not capabilities.enabled("undo_tree") then
  return {}
end

return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undo tree" },
  },
  config = function()
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_DiffAutoOpen = 1
    vim.g.undotree_HelpLine = 0
  end,
}
