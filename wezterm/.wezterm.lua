local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local home = os.getenv("HOME") or ""
local root = os.getenv("DOTFILES_ROOT")
local mode = os.getenv("DOTFILES_WEZTERM_MODE") or "normal"

if mode ~= "minimal" and mode ~= "normal" and mode ~= "aesthetic" then
  wezterm.log_warn("Unknown DOTFILES_WEZTERM_MODE=" .. mode .. "; using normal")
  mode = "normal"
end

local function find_command(command)
  local handle = io.popen("command -v " .. command .. " 2>/dev/null")
  if not handle then
    return nil
  end
  local path = handle:read("*a") or ""
  handle:close()
  path = path:gsub("%s+$", "")
  return path ~= "" and path or nil
end

local function file_exists(path)
  if not path or path == "" then
    return false
  end
  local handle = io.open(path, "rb")
  if handle then
    handle:close()
    return true
  end
  return false
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

local function build_index(pattern, suffixes)
  local entries = {}
  local ok, paths = pcall(wezterm.glob, pattern)
  if not ok then
    return entries
  end
  for _, path in ipairs(paths) do
    if has_suffix(path, suffixes) and file_exists(path) then
      table.insert(entries, path)
    end
  end
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
  wezterm.log_info("tmux not found; falling back to " .. shell)
end

local function tmux_binding(key)
  return wezterm.action.SendString("\x01" .. key)
end

config.keys = {
  { key = "L", mods = "CTRL|SHIFT", action = act.OpenLinkAtMouseCursor },
  { key = "h", mods = "ALT", action = tmux_binding("h") },
  { key = "j", mods = "ALT", action = tmux_binding("j") },
  { key = "k", mods = "ALT", action = tmux_binding("k") },
  { key = "l", mods = "ALT", action = tmux_binding("l") },
}

if mode == "aesthetic" then
  if not root or root == "" then
    wezterm.log_warn("aesthetic mode requires DOTFILES_ROOT to locate local assets")
  else
    math.randomseed(os.time())
    math.random()
    math.random()
    math.random()

    local brightness = 0.03
    local background_folder = os.getenv("DOTFILES_WEZTERM_BG_DIR") or (root .. "/wezterm/bg")
    local music_folder = os.getenv("DOTFILES_WEZTERM_MUSIC_DIR") or (root .. "/wezterm/sd")
    local configured_background = os.getenv("DOTFILES_WEZTERM_BG")
    local background_index = build_index(background_folder .. "/*", { ".png", ".jpg", ".jpeg", ".webp" })
    local music_index = build_index(music_folder .. "/*", { ".mp3", ".flac", ".wav", ".m4a" })

    if file_exists(configured_background) then
      table.insert(background_index, 1, configured_background)
    end

    local function random_entry(entries)
      if #entries == 0 then
        return nil
      end
      return entries[math.random(#entries)]
    end

    local current_background = random_entry(background_index)
    if current_background then
      config.window_background_image = current_background
      config.window_background_image_hsb = {
        brightness = brightness,
        hue = 1.0,
        saturation = 0.8,
      }
      config.window_background_opacity = 0.30
    end

    local mpv_path = find_command("mpv")
    local pkill_path = find_command("pkill")
    local pactl_path = find_command("pactl")

    local function stop_music()
      if pkill_path then
        wezterm.background_child_process({ pkill_path, "-f", "wezterm-music" })
      end
    end

    local function play_music(path)
      if not mpv_path or not file_exists(path) then
        wezterm.log_warn("mpv or music file unavailable")
        return
      end
      stop_music()
      wezterm.background_child_process({
        mpv_path,
        "--title=wezterm-music",
        "--no-video",
        "--loop",
        "--really-quiet",
        path,
      })
    end

    table.insert(config.keys, {
      key = "B",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        local selected = random_entry(background_index)
        if selected then
          current_background = selected
          window:set_config_overrides({ window_background_image = current_background })
        end
      end),
    })

    table.insert(config.keys, {
      key = "UpArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        brightness = math.min(brightness + 0.01, 1.0)
        window:set_config_overrides({
          window_background_image = current_background,
          window_background_image_hsb = { brightness = brightness, hue = 1.0, saturation = 0.8 },
        })
      end),
    })

    table.insert(config.keys, {
      key = "DownArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window)
        brightness = math.max(brightness - 0.01, 0.01)
        window:set_config_overrides({
          window_background_image = current_background,
          window_background_image_hsb = { brightness = brightness, hue = 1.0, saturation = 0.8 },
        })
      end),
    })

    table.insert(config.keys, {
      key = "M",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function()
        play_music(random_entry(music_index))
      end),
    })
    table.insert(config.keys, {
      key = "X",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(stop_music),
    })

    if pactl_path then
      table.insert(config.keys, {
        key = "+",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function()
          wezterm.background_child_process({ pactl_path, "set-sink-volume", "@DEFAULT_SINK@", "+5%" })
        end),
      })
      table.insert(config.keys, {
        key = "-",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function()
          wezterm.background_child_process({ pactl_path, "set-sink-volume", "@DEFAULT_SINK@", "-5%" })
        end),
      })
    end
  end
end

wezterm.on("gui-startup", function()
  wezterm.log_info("dotfiles WezTerm mode: " .. mode)
end)

return config
