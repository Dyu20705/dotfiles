local config_path = assert(arg[1], "treesitter config path is required")

local notifications = {}
_G.vim = {
  log = { levels = { WARN = 2 } },
  notify = function(message, level)
    notifications[#notifications + 1] = { message = message, level = level }
  end,
  schedule = function(callback)
    callback()
  end,
}

local spec = dofile(config_path)
assert(type(spec) == "table", "treesitter plugin spec must be a table")
assert(type(spec.config) == "function", "treesitter plugin spec must define config")

package.loaded["nvim-treesitter.configs"] = nil
package.preload["nvim-treesitter.configs"] = nil

local ok, error_message = pcall(spec.config, nil, spec.opts)
assert(ok, "missing treesitter module aborted bootstrap: " .. tostring(error_message))
assert(#notifications == 1, "missing treesitter module should emit one warning")

local configured_opts
notifications = {}
package.preload["nvim-treesitter.configs"] = function()
  return {
    setup = function(opts)
      configured_opts = opts
    end,
  }
end

ok, error_message = pcall(spec.config, nil, spec.opts)
assert(ok, "available treesitter module failed configuration: " .. tostring(error_message))
assert(configured_opts == spec.opts, "treesitter setup did not receive the declared opts")
assert(#notifications == 0, "available treesitter module emitted a bootstrap warning")

print("treesitter bootstrap spec: PASS")
