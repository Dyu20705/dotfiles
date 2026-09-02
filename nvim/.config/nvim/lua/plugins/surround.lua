return {
  'kylechui/nvim-surround',
  version = '*',
  event = 'VeryLazy',
  keys = {
    { 'ys',  desc = 'Add surround', mode = 'n' },
    { 'yS',  desc = 'Add surround line', mode = 'n' },
    { 'yss', desc = 'Surround line', mode = 'n' },
    { 'ySS', desc = 'Surround line (linewise)', mode = 'n' },
    { 'S',   desc = 'Add surround (visual)', mode = 'x' },
    { 'gS',  desc = 'Add surround line (visual)', mode = 'x' },
    { 'ds',  desc = 'Delete surround', mode = 'n' },
    { 'cs',  desc = 'Change surround', mode = 'n' },
  },
  opts = {},
}
