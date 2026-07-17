vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.colorcolumn = "94"
vim.opt.clipboard = "unnamedplus"
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without replacing register" })

local function apply_line_number_highlights()
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#6c7086" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#ead84e" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_line_number_highlights,
})
apply_line_number_highlights()
