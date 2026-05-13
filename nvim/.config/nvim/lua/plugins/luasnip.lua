-- Engine snippet mạnh mẽ, tích hợp với cmp và hỗ trợ snippet động Lua
return {
  'L3MON4D3/LuaSnip',
  version = 'v2.*',                     -- phiên bản ổn định
  dependencies = { 'rafamadriz/friendly-snippets' },
  event = 'InsertEnter',
  keys = {
    { '<C-k>', function() return require('luasnip').jump(1) end,  mode = { 'i', 's' }, desc = 'Nhảy tới placeholder tiếp theo' },
    { '<C-j>', function() return require('luasnip').jump(-1) end, mode = { 'i', 's' }, desc = 'Nhảy về placeholder trước' },
    { '<C-l>', function()
        if require('luasnip').choice_active() then
          require('luasnip').change_choice(1)
        end
      end, mode = { 'i', 's' }, desc = 'Chuyển lựa chọn trong snippet' },
  },
  opts = {
    history = true,
    updateevents = 'TextChanged,TextChangedI',
    enable_autosnippets = true,
    store_selection_keys = '<Tab>',
    ext_opts = {
      [require('luasnip.util.types').choiceNode] = {
        active = { virt_text = { { '●', 'GruvboxOrange' } } },
      },
    },
  },
  config = function(_, opts)
    require('luasnip').setup(opts)
    require('luasnip.loaders.from_vscode').lazy_load()
    require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })
  end,
}
