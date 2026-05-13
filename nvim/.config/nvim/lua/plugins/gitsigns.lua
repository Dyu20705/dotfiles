-- lua/plugins/gitsigns.lua
return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },    -- load when reading any file
  opts = {
    signs = {
      add          = { text = '│' },
      change       = { text = '│' },
      delete       = { text = '_' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    },
    signcolumn = true,
    numhl      = false,      -- numbers will not be highlighted
    linehl     = false,
    word_diff  = false,
    watch_gitdir = {
      follow_files = true,
      interval = 1000,
    },
    attach_to_untracked = true,
    current_line_blame = false,      -- toggled on demand via keymap
    current_line_blame_opts = { delay = 100, virtual_text_pos = 'eol' },
    update_debounce = 200,
    max_file_length = 40000,
    preview_config = {
      border = 'rounded',
      style = 'minimal',
    },
  },
  keys = {
    { ']c',   function() require('gitsigns').next_hunk() end, desc = 'Next Git hunk' },
    { '[c',   function() require('gitsigns').prev_hunk() end, desc = 'Previous Git hunk' },
    { '<leader>hs',  '<cmd>Gitsigns stage_hunk<CR>', desc = 'Stage hunk' },
    { '<leader>hr',  '<cmd>Gitsigns reset_hunk<CR>', desc = 'Reset hunk' },
    { '<leader>hS',  '<cmd>Gitsigns stage_buffer<CR>', desc = 'Stage buffer' },
    { '<leader>hu',  '<cmd>Gitsigns undo_stage_hunk<CR>', desc = 'Undo stage hunk' },
    { '<leader>hR',  '<cmd>Gitsigns reset_buffer<CR>', desc = 'Reset buffer' },
    { '<leader>hp',  '<cmd>Gitsigns preview_hunk<CR>', desc = 'Preview hunk' },
    { '<leader>hb',  function() require('gitsigns').blame_line { full = true } end, desc = 'Blame line' },
    { '<leader>hB',  '<cmd>Gitsigns toggle_current_line_blame<CR>', desc = 'Toggle line blame' },
    { '<leader>hd',  '<cmd>Gitsigns diffthis<CR>', desc = 'Diff against index' },
    { '<leader>hD',  function() require('gitsigns').diffthis('~') end, desc = 'Diff against last commit' },
    { '<leader>gtb', '<cmd>Gitsigns toggle_signs<CR>', desc = 'Toggle signs' },
  },
}
