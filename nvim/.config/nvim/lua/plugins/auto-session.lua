local capabilities = require("config.capabilities")
if not capabilities.enabled("session") then
  return {}
end

return {
  "rmagatti/auto-session",
  lazy = true,
  priority = 5,
  opts = {
    log_level = "error",
    auto_session_suppress_dirs = { "~/", "/", "~/.local/share/nvim" },
    auto_save_enabled = true,
    auto_restore_enabled = false,
    cwd_change_handling = true,
  },
  keys = {
    { "<leader>ws", "<cmd>SessionSave<cr>", desc = "Save editor session" },
    { "<leader>wr", "<cmd>SessionRestore<cr>", desc = "Restore editor session" },
  },
}
