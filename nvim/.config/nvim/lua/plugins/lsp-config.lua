local languages = require("config.languages")

return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog" },
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    cmd = { "LspInstall", "LspUninstall" },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {},
      automatic_enable = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      local function setup(server_name, server_config)
        server_config = server_config or {}
        server_config.capabilities = vim.tbl_deep_extend(
          "force",
          {},
          capabilities,
          server_config.capabilities or {}
        )
        vim.lsp.config(server_name, server_config)
      end

      setup("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
            completion = { callSnippet = "Replace" },
          },
        },
      })

      for _, server_name in ipairs({
        "pyright",
        "ts_ls",
        "html",
        "cssls",
        "jsonls",
        "yamlls",
        "bashls",
        "clangd",
        "rust_analyzer",
        "gopls",
        "dockerls",
        "terraformls",
      }) do
        setup(server_name)
      end

      vim.lsp.enable(languages.servers())

      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP hover" })
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP definition" })
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "LSP declaration" })
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "LSP implementation" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "LSP references" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP rename" })
      vim.keymap.set(
        { "n", "v" },
        "<leader>ca",
        vim.lsp.buf.code_action,
        { desc = "LSP code action" }
      )
    end,
  },
}
