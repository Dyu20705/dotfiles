return {
  'L3MON4D3/LuaSnip',
  version = 'v2.*',
  dependencies = { 'rafamadriz/friendly-snippets' },
  event = 'InsertEnter',
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
