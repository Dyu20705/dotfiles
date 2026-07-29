local capabilities = require("config.capabilities")
if not capabilities.enabled("outline") then
  return {}
end

return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
  },
  cmd = { "AerialToggle", "AerialOpen", "AerialClose" },
  keys = {
    { "<leader>a", "<cmd>AerialToggle<cr>", desc = "Toggle symbol outline" },
  },
  opts = {
    attach_mode = "global",
    backends = { "treesitter", "lsp" },
    layout = {
      min_width = 28,
      max_width = 40,
      default_direction = "left",
    },
    show_guides = true,
    filter_kind = false,
    update_delay = 300,
    highlight_on_hover = true,
    highlight_on_jump = true,
  },
}
