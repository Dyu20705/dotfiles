local capabilities = require("config.capabilities")
if not capabilities.enabled("git_ui") then
  return {}
end

return {
  "NeogitOrg/neogit",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Neogit",
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>", desc = "Open Neogit" },
  },
  opts = {
    kind = "tab",
    disable_signs = false,
    disable_hint = false,
    disable_context_highlighting = false,
    disable_commit_confirmation = false,
    signs = {
      section = { ">", "v" },
      item = { ">", "v" },
      hunk = { "", "" },
    },
    integrations = { diffview = false },
  },
}
