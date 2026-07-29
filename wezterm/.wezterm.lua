local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local home = os.getenv("HOME") or ""
local mode = os.getenv("DOTFILES_WEZTERM_MODE") or "normal"

if mode ~= "minimal" and mode ~= "normal" and mode ~= "aesthetic" then
  wezterm.log_warn("Unknown DOTFILES_WEZTERM_MODE=" .. mode .. "; using normal")
  mode = "normal"
end

local function join(base, child)
  if base == "" then
    return child
  end
  return base:gsub("/+$", "") .. "/" .. child:gsub("^/+", "")
end

local function file_readable(path)
  if not path or path == "" or path:find("[\r\n]") then
    return false
  end
  local handle = io.open(path, "rb")
  if not handle then
    return false
  end
  handle:close()
  return true
end

local function has_suffix(path, suffixes)
  local lower = string.lower(path)
  for _, suffix in ipairs(suffixes) do
    if lower:sub(-#suffix) == suffix then
      return true
    end
  end
  return false
end

local function find_command(command)
  if not command:match("^[%w_.-]+$") then
    return nil
  end
  for directory in (os.getenv("PATH") or ""):gmatch("[^:]+") do
    local candidate = join(directory, command)
    if file_readable(candidate) then
      return candidate
    end
  end
  return nil
end

local function dirname(path)
  if not path or path == "" or path:find("[\r\n]") then
    return nil
  end
  return path:gsub("/+$", ""):match("^(.*)/[^/]+$")
end

local function root_from_wezterm_path(path)
  local directory = dirname(path)
  if directory and directory:match("/wezterm$") then
    return dirname(directory)
  end
  return nil
end

local function is_checkout_root(candidate)
  return candidate ~= nil
    and candidate ~= ""
    and file_readable(join(candidate, "wezterm/.wezterm.lua"))
end

local config_dir = wezterm.config_dir or "."
local root_candidates = {}
local function add_root_candidate(candidate)
  if candidate and candidate ~= "" then
    root_candidates[#root_candidates + 1] = candidate
  end
end

add_root_candidate(os.getenv("DOTFILES_ROOT"))
add_root_candidate(root_from_wezterm_path(wezterm.config_file))
add_root_candidate(config_dir:match("^(.*)/wezterm/?$"))
add_root_candidate(join(home, "dotfiles"))
add_root_candidate(join(home, "src/dotfiles"))

local root
for _, candidate in ipairs(root_candidates) do
  if is_checkout_root(candidate) then
    root = candidate
    break
  end
end
root = root or root_from_wezterm_path(wezterm.config_file) or config_dir

local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then
  state_home = join(home, ".local/state")
end
local state_dir = join(state_home, "dotfiles/wezterm")

local function read_state(name)
  local handle = io.open(join(state_dir, name), "rb")
  if not handle then
    return nil
  end
  local value = handle:read("*l")
  handle:close()
  if not value or value == "" or value:find("[\r\n]") then
    return nil
  end
  return value
end

local function valid_number(value, minimum, maximum)
  local number = tonumber(value)
  if not number or number ~= number or number < minimum or number > maximum then
    return nil
  end
  return number
end

local image_suffixes = { ".png", ".jpg", ".jpeg", ".webp" }
local music_suffixes = { ".mp3", ".flac", ".wav", ".m4a", ".ogg", ".opus" }

local function valid_asset(path, suffixes)
  return file_readable(path) and has_suffix(path, suffixes)
end

local function build_index(directory, suffixes)
  local entries = {}
  local seen = {}
  local ok, paths = pcall(wezterm.glob, join(directory, "*"))
  if not ok or type(paths) ~= "table" then
    return entries
  end
  for _, path in ipairs(paths) do
    if not seen[path] and valid_asset(path, suffixes) then
      seen[path] = true
      entries[#entries + 1] = path
    end
  end
  table.sort(entries)
  return entries
end

config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.max_fps = mode == "aesthetic" and 120 or 60
config.color_scheme = "Tokyo Night"
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", weight = "Medium" },
  "JetBrains Mono",
  "Noto Sans Mono",
})
config.font_size = 22
config.term = "xterm-256color"
config.default_cursor_style = "BlinkingUnderline"
config.cursor_thickness = 2

local tmux_path = find_command("tmux")
if tmux_path then
  config.default_prog = { tmux_path, "new-session", "-A", "-s", "main" }
else
  local shell = os.getenv("SHELL") or "/bin/sh"
  config.default_prog = { shell, "-l" }
  wezterm.log_info("tmux not found; falling back to the configured shell")
end

config.keys = {
  { key = "L", mods = "CTRL|SHIFT", action = act.OpenLinkAtMouseCursor },
}

if mode ~= "minimal" then
  local random_seed = os.time()
  if wezterm.procinfo and wezterm.procinfo.pid then
    local ok, pid = pcall(wezterm.procinfo.pid)
    if ok and type(pid) == "number" then
      random_seed = random_seed + pid
    end
  end
  math.randomseed(random_seed)
  math.random()

  local configured_background_dir = os.getenv("DOTFILES_WEZTERM_BG_DIR")
  local background_dir = configured_background_dir or join(root, "wezterm/bg")
  local music_dir = os.getenv("DOTFILES_WEZTERM_MUSIC_DIR")
    or join(root, "wezterm/sd")
  local background_index = build_index(background_dir, image_suffixes)
  if #background_index == 0 and not configured_background_dir then
    background_dir = join(home, "bg")
    background_index = build_index(background_dir, image_suffixes)
  end
  local music_index = build_index(music_dir, music_suffixes)

  local configured_background = os.getenv("DOTFILES_WEZTERM_BG")
  local persisted_background = read_state("background")
  local legacy_background = join(background_dir, "bg.png")
  local current_background
  if valid_asset(configured_background, image_suffixes) then
    current_background = configured_background
  elseif valid_asset(persisted_background, image_suffixes) then
    current_background = persisted_background
  elseif valid_asset(legacy_background, image_suffixes) then
    current_background = legacy_background
  else
    current_background = background_index[1]
  end

  local configured_brightness = valid_number(
    os.getenv("DOTFILES_WEZTERM_BRIGHTNESS"),
    0.01,
    1.0
  )
  local persisted_brightness = valid_number(read_state("brightness"), 0.01, 1.0)
  local brightness = configured_brightness or persisted_brightness or 0.03
  local opacity = valid_number(os.getenv("DOTFILES_WEZTERM_OPACITY"), 0.05, 1.0)
    or 0.30

  if current_background then
    config.window_background_image = current_background
    config.window_background_image_hsb = {
      brightness = brightness,
      hue = 1.0,
      saturation = 0.8,
    }
    config.window_background_opacity = opacity
  end

  local controller = os.getenv("DOTFILES_WEZTERM_MEDIA_CONTROLLER")
  if not file_readable(controller) then
    local installed_controller = join(home, ".local/bin/dotfiles-wezterm-media")
    local checkout_controller = join(root, "scripts/wezterm-media.sh")
    if file_readable(installed_controller) then
      controller = installed_controller
    elseif file_readable(checkout_controller) then
      controller = checkout_controller
    else
      controller = nil
    end
  end

  local warning_shown = {
    controller = false,
    mpv = false,
    music = false,
    volume = false,
  }

  local function warn_once(window, kind, message)
    if warning_shown[kind] then
      return
    end
    warning_shown[kind] = true
    if window and window.toast_notification then
      window:toast_notification("WezTerm media", message, nil, 3000)
    else
      wezterm.log_warn(message)
    end
  end

  local function controller_available(window)
    if controller then
      return true
    end
    warn_once(window, "controller", "Media controller is unavailable")
    return false
  end

  local function capability(window, name, warning)
    if not controller_available(window) then
      return false
    end
    local ok = wezterm.run_child_process({ controller, "check", name })
    if not ok then
      warn_once(window, name, warning)
      return false
    end
    return true
  end

  local function persist(name, value)
    if controller then
      wezterm.run_child_process({ controller, "state-set", name, tostring(value) })
    end
  end

  local function random_entry(entries)
    if #entries == 0 then
      return nil
    end
    return entries[math.random(#entries)]
  end

  local function apply_background(window, selected)
    if not selected then
      warn_once(window, "background", "No readable background images were found")
      return
    end
    current_background = selected
    persist("background", current_background)
    window:set_config_overrides({
      window_background_image = current_background,
      window_background_image_hsb = {
        brightness = brightness,
        hue = 1.0,
        saturation = 0.8,
      },
      window_background_opacity = opacity,
    })
  end

  local function play(window, track)
    if not track then
      warn_once(window, "music", "No readable music tracks were found")
      return
    end
    if not capability(window, "mpv", "mpv is unavailable; music controls are disabled") then
      return
    end
    wezterm.background_child_process({ controller, "play", track })
  end

  local function stop(window)
    if controller_available(window) then
      wezterm.background_child_process({ controller, "stop" })
    end
  end

  local function volume(window, direction)
    if capability(window, "volume", "No wpctl or pactl command is available") then
      wezterm.background_child_process({ controller, "volume", direction })
    end
  end

  local configured_default_track = os.getenv("DOTFILES_WEZTERM_DEFAULT_TRACK")
  local legacy_default_track = join(music_dir, "bg.mp3")
  local default_track
  if valid_asset(configured_default_track, music_suffixes) then
    default_track = configured_default_track
  elseif valid_asset(legacy_default_track, music_suffixes) then
    default_track = legacy_default_track
  else
    default_track = music_index[1]
  end

  local media_bindings = {
    {
      key = "B",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        apply_background(window, random_entry(background_index))
      end),
    },
    {
      key = "UpArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        brightness = math.min(brightness + 0.01, 1.0)
        persist("brightness", string.format("%.2f", brightness))
        apply_background(window, current_background)
      end),
    },
    {
      key = "DownArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        brightness = math.max(brightness - 0.01, 0.01)
        persist("brightness", string.format("%.2f", brightness))
        apply_background(window, current_background)
      end),
    },
    {
      key = "F6",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        play(window, random_entry(music_index))
      end),
    },
    {
      key = "F7",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(stop),
    },
    {
      key = "F8",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        volume(window, "up")
      end),
    },
    {
      key = "F9",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        volume(window, "down")
      end),
    },
    {
      key = "F10",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        play(window, default_track)
      end),
    },
  }

  for _, binding in ipairs(media_bindings) do
    config.keys[#config.keys + 1] = binding
  end
end

wezterm.on("gui-startup", function()
  wezterm.log_info("dotfiles WezTerm mode: " .. mode .. "; root=" .. root)
end)

return config
