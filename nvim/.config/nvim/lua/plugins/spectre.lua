local capabilities = require("config.capabilities")
if not capabilities.enabled("project_replace") then
  return {}
end

return {
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Spectre",
  keys = {
    { "<leader>S", "<cmd>Spectre<cr>", desc = "Project search and replace" },
    {
      "<leader>sw",
      function()
        require("spectre").open_visual({ select_word = true })
      end,
      desc = "Search current word",
    },
  },
  opts = {
    open_cmd = "vnew",
    live_update = true,
    is_block_ui_break = true,
  },
}
