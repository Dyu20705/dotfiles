local M = {}

local enabled = {}
local enable_all = vim.env.DOTFILES_NVIM_EXTENDED == "1"

for name in (vim.env.DOTFILES_NVIM_CAPABILITIES or ""):gmatch("[^,%s]+") do
  enabled[name] = true
end

function M.enabled(name)
  return enable_all or enabled[name] == true
end

function M.active()
  if enable_all then
    return { "*" }
  end

  local names = {}
  for name in pairs(enabled) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return M
