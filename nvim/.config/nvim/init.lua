local function echo_error(message)
  vim.api.nvim_echo({ { "dotfiles: " .. message, "ErrorMsg" } }, true, {})
end

-- `nvim -u /path/to/init.lua` does not automatically make that file's parent
-- the standard config directory. Add it to runtimepath so headless tests,
-- alternate profiles and clean-room installs resolve `lua/` modules exactly as
-- a deployed ~/.config/nvim installation does.
local source = debug.getinfo(1, "S").source
local config_file = vim.env.MYVIMRC
if not config_file or config_file == "" then
  config_file = source:sub(1, 1) == "@" and source:sub(2) or source
end
local config_dir = vim.fn.fnamemodify(config_file, ":p:h")
if not vim.tbl_contains(vim.opt.runtimepath:get(), config_dir) then
  vim.opt.runtimepath:prepend(config_dir)
end

if vim.fn.has("nvim-0.11.3") == 0 then
  echo_error("Neovim 0.11.3 or newer is required")
  return
end

local core_modules = { "vim-options", "debug-commands" }
for _, module_name in ipairs(core_modules) do
  local ok, error_message = pcall(require, module_name)
  if not ok then
    echo_error("failed to load " .. module_name .. ": " .. tostring(error_message))
    return
  end
end
vim.g.dotfiles_core_ready = true

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

vim.opt.runtimepath:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if not ok then
  echo_error("failed to load lazy.nvim: " .. tostring(lazy))
  return
end

lazy.setup("plugins", {
  change_detection = { notify = false },
  checker = { enabled = false },
})
vim.g.dotfiles_init_complete = true
