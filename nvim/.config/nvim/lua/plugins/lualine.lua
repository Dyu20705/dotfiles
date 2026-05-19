-- Statusline hiện đại, nhiều thông tin, phối màu Catppuccin
return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 
        'nvim-tree/nvim-web-devicons',
        'catppuccin/nvim',
  },
  lazy = false,
  opts = {
    options = {
      theme = 'catppuccin',
      section_separators = { left = '', right = '' },
      component_separators = { left = '', right = '' },
      globalstatus = true,
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { 'filename' },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
    extensions = { 'neo-tree', 'trouble', 'toggleterm', 'aerial' },
  },
}
