local config_path = assert(arg[1], "config path is required")
local scenario = assert(arg[2], "scenario is required")

local calls = { background = {}, run = {}, toasts = {}, warnings = {} }

local function split(value)
  local items = {}
  for item in (value or ""):gmatch("[^;]+") do
    table.insert(items, item)
  end
  return items
end

local wezterm = {
  action = {
    OpenLinkAtMouseCursor = { kind = "open-link" },
    SendString = function(value)
      return { kind = "send-string", value = value }
    end,
  },
  config_dir = assert(os.getenv("WEZTERM_TEST_CONFIG_DIR")),
  procinfo = { pid = function() return 1234 end },
}

function wezterm.config_builder()
  return {}
end

function wezterm.font_with_fallback(fonts)
  return fonts
end

function wezterm.glob(_pattern)
  return split(os.getenv("WEZTERM_TEST_GLOB"))
end

function wezterm.action_callback(callback)
  return { kind = "callback", callback = callback }
end

function wezterm.background_child_process(arguments)
  table.insert(calls.background, arguments)
end

function wezterm.run_child_process(arguments)
  table.insert(calls.run, arguments)
  if arguments[2] == "check" and arguments[3] == "mpv" then
    return os.getenv("WEZTERM_TEST_MPV") == "1", "", ""
  end
  if arguments[2] == "check" and arguments[3] == "volume" then
    return os.getenv("WEZTERM_TEST_VOLUME") == "1", "", ""
  end
  return true, "", ""
end

function wezterm.log_warn(message)
  table.insert(calls.warnings, message)
end

function wezterm.log_info(_message) end
function wezterm.on(_name, _callback) end

package.preload.wezterm = function()
  return wezterm
end

local config = dofile(config_path)
assert(type(config) == "table", "config must return a table")
assert(#calls.background == 0, "config evaluation started a background process")
assert(#calls.run == 0, "config evaluation started a foreground process")

local function binding(key, mods)
  for _, candidate in ipairs(config.keys or {}) do
    if candidate.key == key and candidate.mods == mods then
      return candidate
    end
  end
  return nil
end

assert(binding("F5", "NONE") == nil, "WezTerm steals the Neovim F5 key")
assert(binding("F11", "NONE") == nil, "WezTerm steals the Neovim F11 key")
assert(binding("F12", "NONE") == nil, "WezTerm steals the Neovim F12 key")

local window = { overrides = nil }
function window:set_config_overrides(overrides)
  self.overrides = overrides
end
function window:toast_notification(_title, message, _url, _timeout)
  table.insert(calls.toasts, message)
end

if scenario == "minimal" then
  assert(config.window_background_image == nil, "minimal mode configured a background")
  assert(binding("F10", "CTRL|SHIFT") == nil, "minimal mode configured media keys")
elseif scenario == "normal" then
  assert(config.window_background_image == assert(os.getenv("WEZTERM_TEST_EXPECTED_BG")))
  assert(config.window_background_image_hsb.brightness == 0.03)
  assert(binding("F10", "CTRL|SHIFT"), "normal mode is missing the default-track key")
  assert(binding("F10", "NONE") == nil, "normal mode steals the Neovim F10 key")
elseif scenario == "aesthetic" then
  assert(binding("F6", "NONE"), "aesthetic mode is missing legacy F6")
  assert(binding("F10", "NONE"), "aesthetic mode is missing legacy F10")
elseif scenario == "reload" then
  assert(config.window_background_image == assert(os.getenv("WEZTERM_TEST_EXPECTED_BG")))
  assert(config.window_background_image_hsb.brightness == 0.42)
elseif scenario == "missing" then
  assert(config.window_background_image == nil, "missing assets should use a plain background")
  local play = assert(binding("F6", "CTRL|SHIFT"), "music key is missing")
  play.action.callback(window)
  assert(#calls.toasts == 1, "missing music should produce one concise warning")
  assert(#calls.background == 0, "missing music started a process")
elseif scenario == "missing-mpv" then
  local play = assert(binding("F6", "CTRL|SHIFT"), "music key is missing")
  play.action.callback(window)
  play.action.callback(window)
  assert(#calls.toasts == 1, "missing mpv warning should be shown only once")
  assert(#calls.background == 0, "missing mpv started a process")
elseif scenario == "callbacks" then
  local rotate = assert(binding("B", "CTRL|SHIFT"))
  for _ = 1, 20 do
    rotate.action.callback(window)
    assert(window.overrides and window.overrides.window_background_image)
    assert(
      window.overrides.window_background_image:find(
        assert(os.getenv("WEZTERM_TEST_BG_PREFIX")),
        1,
        true
      ) == 1,
      "random background escaped the readable fixture directory"
    )
  end
  assert(calls.run[20][2] == "state-set" and calls.run[20][3] == "background")
  calls.run = {}

  local play = assert(binding("F6", "CTRL|SHIFT"))
  play.action.callback(window)
  assert(calls.run[1][2] == "check" and calls.run[1][3] == "mpv")
  assert(calls.background[1][2] == "play")

  local stop = assert(binding("F7", "CTRL|SHIFT"))
  stop.action.callback(window)
  assert(calls.background[2][2] == "stop")

  local volume = assert(binding("F8", "CTRL|SHIFT"))
  volume.action.callback(window)
  assert(calls.run[2][2] == "check" and calls.run[2][3] == "volume")
  assert(calls.background[3][2] == "volume" and calls.background[3][3] == "up")
else
  error("unknown scenario: " .. scenario)
end
