local capabilities = require("config.capabilities")
if not capabilities.enabled("test") then
  return {}
end

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = "Neotest",
  keys = {
    {
      "<leader>tn",
      function()
        require("neotest").run.run()
      end,
      desc = "Run nearest configured test",
    },
    {
      "<leader>tf",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Run current test file",
    },
    { "<leader>to", "<cmd>Neotest output<cr>", desc = "Test output" },
    { "<leader>tp", "<cmd>Neotest summary<cr>", desc = "Test summary" },
  },
  opts = {
    adapters = {},
    status = { virtual_text = true },
    output = { open_on_run = true },
  },
}
