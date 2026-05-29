-- selene: allow(global_usage)

local M = {}

local function notify(value, title)
  vim.notify(vim.inspect(value), vim.log.levels.INFO, {
    title = title,
    on_open = function(win)
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      if not pcall(vim.treesitter.start, buf, "lua") then
        vim.bo[buf].filetype = "lua"
      end
    end,
  })
end

function M.get_loc()
  local me = debug.getinfo(1, "S")
  local level = 2
  local info = debug.getinfo(level, "S")

  while info and (info.source == me.source or info.source == "@" .. vim.env.MYVIMRC or info.what ~= "Lua") do
    level = level + 1
    info = debug.getinfo(level, "S")
  end

  info = info or me
  local source = info.source:sub(2)
  source = vim.loop.fs_realpath(source) or source

  return source .. ":" .. info.linedefined
end

---@param value any
---@param opts? {loc:string}
function M._dump(value, opts)
  opts = opts or {}
  opts.loc = opts.loc or M.get_loc()

  if vim.in_fast_event() then
    return vim.schedule(function()
      M._dump(value, opts)
    end)
  end

  opts.loc = vim.fn.fnamemodify(opts.loc, ":~:.")
  notify(value, "Debug: " .. opts.loc)
end

function M.dump(...)
  local value = { ... }
  if vim.tbl_isempty(value) then
    value = nil
  else
    local is_list = vim.islist or vim.tbl_islist
    value = is_list(value) and vim.tbl_count(value) <= 1 and value[1] or value
  end
  M._dump(value)
end

function M.extmark_leaks()
  local namespaces = vim.api.nvim_get_namespaces()
  local counts = {}

  for name, ns in pairs(namespaces) do
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local count = #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
      if count > 0 then
        counts[#counts + 1] = {
          name = name,
          buf = buf,
          count = count,
          ft = vim.bo[buf].ft,
        }
      end
    end
  end

  table.sort(counts, function(a, b)
    return a.count > b.count
  end)

  notify(counts, "Debug extmark leaks")
end

local function estimate_size(value, visited)
  if value == nil then
    return 0
  end

  visited = visited or {}

  if visited[value] then
    return 0
  end
  visited[value] = true

  local bytes = 0
  local value_type = type(value)

  if value_type == "boolean" then
    bytes = 4
  elseif value_type == "number" then
    bytes = 8
  elseif value_type == "string" then
    bytes = string.len(value) + 24
  elseif value_type == "function" then
    bytes = 32
    local i = 1
    while true do
      local name, upvalue = debug.getupvalue(value, i)
      if not name then
        break
      end
      bytes = bytes + estimate_size(upvalue, visited)
      i = i + 1
    end
  elseif value_type == "table" then
    bytes = 40
    for key, entry in pairs(value) do
      bytes = bytes + estimate_size(key, visited) + estimate_size(entry, visited)
    end
    local metatable = debug.getmetatable(value)
    if metatable then
      bytes = bytes + estimate_size(metatable, visited)
    end
  end

  return bytes
end

function M.module_leaks(filter)
  local sizes = {}

  for modname, mod in pairs(package.loaded) do
    if not filter or modname:match(filter) then
      local root = modname:match("^([^%.]+)%..*$") or modname
      sizes[root] = sizes[root] or { mod = root, size = 0 }
      sizes[root].size = sizes[root].size + estimate_size(mod) / 1024 / 1024
    end
  end

  sizes = vim.tbl_values(sizes)
  table.sort(sizes, function(a, b)
    return a.size > b.size
  end)

  notify(sizes, "Debug module leaks")
end

function M.get_upvalue(func, name)
  local i = 1
  while true do
    local upvalue_name, upvalue = debug.getupvalue(func, i)
    if not upvalue_name then
      break
    end
    if upvalue_name == name then
      return upvalue
    end
    i = i + 1
  end
end

return M