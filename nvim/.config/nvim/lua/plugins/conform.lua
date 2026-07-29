return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>fm",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format current buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format", "black", stop_after_first = true },
      rust = { "rustfmt" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      go = { "gofmt" },
      terraform = { "terraform_fmt" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "fallback",
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    notify_on_error = true,
    notify_no_formatters = false,
  },
}
