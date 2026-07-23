local capabilities = require("config.capabilities")
if not capabilities.enabled("terminal") then
  return {}
end

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<leader>ot", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    { "<leader>of", "<cmd>ToggleTerm direction=float<CR>", desc = "Open floating terminal" },
    { "<leader>oh", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Open horizontal terminal" },
    { "<leader>ov", "<cmd>ToggleTerm direction=vertical<CR>", desc = "Open vertical terminal" },
  },
  opts = {
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return math.floor(vim.o.columns * 0.4)
      end
    end,
    open_mapping = nil,
    hide_numbers = true,
    shade_terminals = false,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    persist_size = false,
    direction = "float",
    float_opts = {
      border = "curved",
      width = math.floor(vim.o.columns * 0.8),
      height = math.floor(vim.o.lines * 0.8),
    },
  },
}
