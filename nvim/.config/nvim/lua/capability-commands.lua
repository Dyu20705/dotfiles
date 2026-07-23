local capabilities = require("config.capabilities")
local languages = require("config.languages")

vim.api.nvim_create_user_command("DotfilesCapabilities", function()
  vim.notify(vim.inspect({
    extended = capabilities.active(),
    language_groups = languages.selected_groups(),
    language_servers = languages.health(),
  }), vim.log.levels.INFO, { title = "Dotfiles capabilities" })
end, { desc = "Show enabled optional capabilities and language tooling health" })
