local config_path = assert(arg[1], "config path is required")
local scenario = assert(arg[2], "scenario is required")

local calls = { background = {}, run = {}, toasts = {}, warnings = {} }

local function split(value)
  local items = {}
  for item in (value or ""):gmatch("[^;]+") do
    items[#items + 1] = item
  end
  return items
end

local test_config_dir = assert(os.getenv("WEZTERM_TEST_CONFIG_DIR"))
local wezterm = {
  action = {
    OpenLinkAtMouseCursor = { kind = "open-link" },
    SendString = function(value)
      return { kind = "send-string", value = value }
    end,
  },
  config_dir = test_config_dir,
  config_file = os.getenv("WEZTERM_TEST_CONFIG_FILE") or (test_config_dir .. "/.wezterm.lua"),
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
  calls.background[#calls.background + 1] = arguments
end

function wezterm.run_child_process(arguments)
  calls.run[#calls.run + 1] = arguments
  if arguments[2] == "check" and arguments[3] == "mpv" then
    return os.getenv("WEZTERM_TEST_MPV") == "1", "", ""
  end
  if arguments[2] == "check" and arguments[3] == "volume" then
    return os.getenv("WEZTERM_TEST_VOLUME") == "1", "", ""
  end
  return true, "", ""
end

function wezterm.log_warn(message)
  calls.warnings[#calls.warnings + 1] = message
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

for _, key in ipairs({ "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12" }) do
  assert(binding(key, "NONE") == nil, "WezTerm steals unmodified " .. key)
end

local window = { overrides = nil }
function window:set_config_overrides(overrides)
  self.overrides = overrides
end
function window:toast_notification(_title, message, _url, _timeout)
  calls.toasts[#calls.toasts + 1] = message
end

if scenario == "minimal" then
  assert(config.window_background_image == nil, "minimal mode configured a background")
  assert(binding("F10", "CTRL|SHIFT") == nil, "minimal mode configured media keys")
elseif scenario == "normal" then
  assert(config.window_background_image == assert(os.getenv("WEZTERM_TEST_EXPECTED_BG")))
  assert(config.window_background_image_hsb.brightness == 0.03)
  assert(binding("F10", "CTRL|SHIFT"), "normal mode is missing the default-track key")
elseif scenario == "aesthetic" then
  assert(binding("F6", "CTRL|SHIFT"), "aesthetic mode is missing modified media keys")
  assert(binding("F10", "CTRL|SHIFT"), "aesthetic mode is missing modified media keys")
  assert(config.max_fps == 120, "aesthetic mode did not enable its visual profile")
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
elseif scenario == "discovered-root" then
  assert(
    config.window_background_image == assert(os.getenv("WEZTERM_TEST_EXPECTED_BG")),
    "config did not discover the checkout background without DOTFILES_ROOT"
  )
  local play = assert(binding("F10", "CTRL|SHIFT"), "default music key is missing")
  play.action.callback(window)
  assert(calls.background[1][2] == "play", "default music did not start")
  assert(
    calls.background[1][3] == assert(os.getenv("WEZTERM_TEST_EXPECTED_TRACK")),
    "config did not discover the checkout music without DOTFILES_ROOT"
  )
else
  error("unknown scenario: " .. scenario)
end
