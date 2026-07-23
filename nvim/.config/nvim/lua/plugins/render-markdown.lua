local capabilities = require("config.capabilities")
if not capabilities.enabled("markdown_ui") then
  return {}
end

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  opts = {
    conceal = false,
    wrap = true,
  },
}
