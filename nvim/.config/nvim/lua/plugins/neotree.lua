return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = { "Neotree", "NeotreeToggle", "NeotreeShow", "NeotreeFocus" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>v", "<cmd>Neotree filesystem reveal left<cr>", desc = "Neo-tree Reveal" },
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          use_libuv_file_watcher = true,
          follow_current_file = {
            enabled = true,
          },
        },
        window = {
          mappings = {
            ["<LeftMouse>"] = "open",
          },
        },
      })
    end,
  },
}
