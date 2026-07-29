return {
  "windwp/nvim-ts-autotag",
  event = { "BufReadPre", "BufNewFile" },
  ft = {
    "html",
    "javascriptreact",
    "typescriptreact",
    "svelte",
    "vue",
    "xml",
  },
  opts = {
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = false,
    },
  },
  config = function(_, opts)
    require("nvim-ts-autotag").setup(opts)
  end,
}
