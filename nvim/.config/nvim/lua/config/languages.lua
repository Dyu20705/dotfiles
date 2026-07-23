local M = {}

M.groups = {
  core = {
    lua_ls = { command = "lua-language-server" },
  },
  python = {
    pyright = { command = "pyright-langserver" },
  },
  web = {
    ts_ls = { command = "typescript-language-server" },
    html = { command = "vscode-html-language-server" },
    cssls = { command = "vscode-css-language-server" },
    jsonls = { command = "vscode-json-language-server" },
    yamlls = { command = "yaml-language-server" },
  },
  shell = {
    bashls = { command = "bash-language-server" },
  },
  systems = {
    clangd = { command = "clangd" },
    rust_analyzer = { command = "rust-analyzer" },
    gopls = { command = "gopls" },
  },
  infra = {
    dockerls = { command = "docker-langserver" },
    terraformls = { command = "terraform-ls" },
  },
}

M.default_groups = { "core", "python", "web", "shell" }

local function selected_groups()
  local value = vim.env.DOTFILES_NVIM_LANGUAGE_GROUPS
  if not value or value == "" then
    return vim.deepcopy(M.default_groups)
  end

  local groups = {}
  local seen = {}
  for group in value:gmatch("[^,%s]+") do
    if M.groups[group] and not seen[group] then
      seen[group] = true
      groups[#groups + 1] = group
    end
  end
  return groups
end

function M.selected_groups()
  return selected_groups()
end

function M.servers()
  local servers = {}
  local seen = {}
  for _, group in ipairs(selected_groups()) do
    for server in pairs(M.groups[group]) do
      if not seen[server] then
        seen[server] = true
        servers[#servers + 1] = server
      end
    end
  end
  table.sort(servers)
  return servers
end

function M.health()
  local result = {}
  for _, group in ipairs(selected_groups()) do
    for server, metadata in pairs(M.groups[group]) do
      result[#result + 1] = {
        group = group,
        server = server,
        command = metadata.command,
        available = vim.fn.executable(metadata.command) == 1,
      }
    end
  end
  table.sort(result, function(left, right)
    return left.server < right.server
  end)
  return result
end

return M
