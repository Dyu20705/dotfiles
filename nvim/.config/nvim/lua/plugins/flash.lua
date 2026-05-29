return {
  'folke/flash.nvim',
  -- load when the user presses one of these keys; we will only set mappings if
  -- those keys are unmapped to avoid clobbering existing behavior
  keys = { 's', 'S', 'r' },
  config = function()
    local ok, flash = pcall(require, 'flash')
    if not ok then return end

    local function has_map(mode, lhs)
      return vim.fn.maparg(lhs, mode) ~= ''
    end

    if not has_map('n', 's') then
      vim.keymap.set('n', 's', function() flash.jump() end, { desc = 'Flash jump (s)' })
    end
    if not has_map('n', 'S') then
      vim.keymap.set('n', 'S', function() flash.jump() end, { desc = 'Flash jump (S)' })
    end
    if not has_map('n', 'r') then
      vim.keymap.set('n', 'r', function() flash.jump() end, { desc = 'Flash jump (r)' })
    end
  end,
}
