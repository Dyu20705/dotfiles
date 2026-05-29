local debug_tools = require('utils.debug')

vim.api.nvim_create_user_command('DebugDump', function(opts)
  if opts.range == 1 then
    local lines = vim.fn.getline(opts.line1, opts.line2)
    debug_tools.dump(lines)
    return
  end

  if opts.args ~= '' then
    debug_tools.dump(opts.args)
    return
  end

  debug_tools.dump(vim.fn.expand('<cword>'))
end, { nargs = '?', range = true })

vim.api.nvim_create_user_command('DebugLoc', function()
  debug_tools.dump(debug_tools.get_loc())
end, {})

vim.api.nvim_create_user_command('DebugExtmarks', function()
  debug_tools.extmark_leaks()
end, {})

vim.api.nvim_create_user_command('DebugModules', function(opts)
  debug_tools.module_leaks(opts.args ~= '' and opts.args or nil)
end, { nargs = '?' })

vim.keymap.set({ 'n', 'v' }, '<leader>dd', '<cmd>DebugDump<cr>', { desc = 'Debug dump word/selection' })
vim.keymap.set('n', '<leader>dl', '<cmd>DebugLoc<cr>', { desc = 'Debug call location' })
vim.keymap.set('n', '<leader>de', '<cmd>DebugExtmarks<cr>', { desc = 'Debug extmark leaks' })
vim.keymap.set('n', '<leader>dm', '<cmd>DebugModules<cr>', { desc = 'Debug module leaks' })