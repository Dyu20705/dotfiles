return {
  "mfussenegger/nvim-lint",
  event = { "BufWritePost" },
  keys = {
    {
      "<leader>xl",
      function()
        require("lint").try_lint()
      end,
      desc = "Lint current buffer",
    },
  },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      lua = { "luacheck" },
      rust = { "clippy" },
      c = { "clangtidy" },
      cpp = { "clangtidy" },
      python = { "pylint" },
    }

    local group = vim.api.nvim_create_augroup("dotfiles-lint", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
