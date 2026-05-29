return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  config = function()
    local ok, rm = pcall(require, 'render_markdown')
    if not ok or not rm.setup then return end
    -- conservative defaults: enable rendering but avoid heavy visual features
    pcall(function()
      rm.setup({
        conceal = false,
        wrap = true,
      })
    end)
  end,
}
