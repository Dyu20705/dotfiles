-- lua/plugins/auto-session.lua
return {
  'rmagatti/auto-session',
  lazy = false,
  priority = 5,
  opts = {
    log_level = 'error',
    auto_session_suppress_dirs = { '~/', '/', '~/.local/share/nvim' },
    auto_save_enabled = true,
    auto_restore_enabled = true,
    cwd_change_handling = true,
    pre_save_cmds = { 'Neotree close' },   -- đóng neo-tree trước khi lưu
    post_restore_cmds = { 'Neotree filesystem reveal left' },
  },
  keys = {
    { '<leader>ws', '<cmd>SessionSave<CR>', desc = 'Lưu session thủ công' },
    { '<leader>wr', '<cmd>SessionRestore<CR>', desc = 'Phục hồi session' },
  },
}
