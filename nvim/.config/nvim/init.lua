local function echo_error(message)
  vim.api.nvim_echo({ { "dotfiles: " .. message, "ErrorMsg" } }, true, {})
end

if vim.fn.has("nvim-0.11.3") == 0 then
  echo_error("Neovim 0.11.3 or newer is required")
  return
end

require("vim-options")
require("debug-commands")

local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local bootstrap_enabled = vim.env.DOTFILES_NVIM_BOOTSTRAP ~= "0"

if not uv.fs_stat(lazypath) then
  if not bootstrap_enabled then
    vim.api.nvim_echo({ { "dotfiles: lazy.nvim is missing; bootstrap disabled", "WarningMsg" } }, true, {})
    return
  end

  if vim.fn.executable("git") ~= 1 then
    echo_error("git is required to install lazy.nvim")
    return
  end

  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 or not uv.fs_stat(lazypath) then
    echo_error("failed to clone lazy.nvim: " .. vim.trim(output or "unknown error"))
    return
  end
end

vim.opt.rtp:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if not ok then
  echo_error("failed to load lazy.nvim: " .. tostring(lazy))
  return
end

lazy.setup("plugins", {
  change_detection = { notify = false },
  checker = { enabled = false },
})
