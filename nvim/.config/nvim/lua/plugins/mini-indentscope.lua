-- lua/plugins/mini-indentscope.lua
return {
  'echasnovski/mini.indentscope',
  version = false,
  event = 'BufReadPost',
  config = function()
    local indentscope = require('mini.indentscope')
    indentscope.setup({
      symbol = '│',
      options = { try_as_border = true },
      draw = {
        delay = 100,
        animation = indentscope.gen_animation.none(),
      },
    })

    -- Textobjects cho indent scope
    vim.keymap.set({ 'o', 'x' }, 'ii', [[<Cmd>lua MiniIndentscope.textobject("i")<CR>]], { desc = 'Inside indent scope' })
    vim.keymap.set({ 'o', 'x' }, 'ai', [[<Cmd>lua MiniIndentscope.textobject("a")<CR>]], { desc = 'Around indent scope' })
  end,
}
