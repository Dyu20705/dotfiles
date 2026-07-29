return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      "vimdoc",
      "query",
      "bash",
      "python",
      "javascript",
      "typescript",
      "tsx",
      "html",
      "css",
      "json",
      "yaml",
      "dockerfile",
      "c",
      "cpp",
      "rust",
      "go",
      "terraform",
      "markdown",
      "markdown_inline",
    },
    sync_install = false,
    auto_install = false,
    highlight = {
      enable = true,
    },
    indent = {
      enable = false,
    },
  },
  config = function(_, opts)
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then
      vim.schedule(function()
        vim.notify(
          "nvim-treesitter is not available yet; run :Lazy sync and restart Neovim",
          vim.log.levels.WARN
        )
      end)
      return
    end

    configs.setup(opts)
  end,
}
