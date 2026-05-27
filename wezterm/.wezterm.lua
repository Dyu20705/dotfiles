local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ============================================================
-- GLOBAL
-- ============================================================

local home = os.getenv("HOME")
math.randomseed(os.time())
math.random(); math.random(); math.random()

-- Runtime mode and environment-aware behavior
-- Modes: "minimal" (fast, no side-effects), "normal" (default), "aesthetic" (opt-in visuals/audio)
local MODE = os.getenv("DOTFILES_WEZTERM_MODE") or "normal"

local brightness = 0.03

local background_folder = home .. "/bg"
local music_folder = home .. "/dotfiles/wezterm/sd"
local bg_image = os.getenv("DOTFILES_WEZTERM_BG") or (home .. "/dotfiles/wezterm/bg/bg.png")
local default_music = music_folder .. "/bg.mp3"

local background_index = {}
local music_index = {}

local function has_suffix(path, suffixes)
    local lower = string.lower(path)
    for _, suffix in ipairs(suffixes) do
        if lower:sub(-#suffix) == suffix then
            return true
        end
    end
    return false
end

local function build_index(pattern, suffixes, fallback)
    local entries = {}
    local seen = {}

    local ok, paths = pcall(wezterm.glob, pattern)
    if ok then
        for _, path in ipairs(paths) do
            if has_suffix(path, suffixes) and not seen[path] then
                seen[path] = true
                table.insert(entries, path)
            end
        end
    end

    if #entries == 0 and fallback then
        table.insert(entries, fallback)
    end

    return entries
end

background_index = build_index(background_folder .. "/*", { ".png", ".jpg", ".jpeg", ".webp" }, bg_image)
music_index = build_index(music_folder .. "/*", { ".mp3", ".flac", ".wav", ".m4a" }, default_music)

local background_cursor = 1

-- ============================================================
-- RANDOM BACKGROUND
-- ============================================================

local function choose_random_background()
    if #background_index == 0 then
        return bg_image
    end
    return background_index[math.random(#background_index)]
end

local function choose_next_background()
    if #background_index == 0 then
        return bg_image
    end

    local selected = background_index[background_cursor]
    background_cursor = background_cursor + 1
    if background_cursor > #background_index then
        background_cursor = 1
    end
    return selected
end

-- ============================================================
-- RANDOM MUSIC
-- ============================================================

local function choose_random_music()
    if #music_index == 0 then
        return default_music
    end
    return music_index[math.random(#music_index)]
end

-- ============================================================
-- MUSIC CONTROL
-- ============================================================

local function stop_music(window, pane)
    -- Tắt mọi mpv (kể cả từ cửa sổ cũ)
    wezterm.background_child_process({ "pkill", "-f", "wezterm-music" })
end

local function play_music(file_path)
    if not file_path then
        wezterm.log_error("Music file not found")
        return
    end

    stop_music()
    wezterm.background_child_process({
        "mpv",
        "--title=wezterm-music",
        "--no-video",
        "--loop",
        "--really-quiet",
        file_path,
    })
    wezterm.log_info("Playing: " .. file_path)
end

local function play_random_music(window, pane)
    local music = choose_random_music()
    if music then
        play_music(music)
    else
        wezterm.log_error("No music found")
    end
end

-- ============================================================
-- BACKGROUND CONFIG
-- ============================================================

config.window_background_image = bg_image
config.window_background_image_hsb = {
    brightness = brightness,
    hue = 1.0,
    saturation = 0.8,
}

config.window_background_opacity = 0.30

-- ============================================================
-- WINDOW
-- ============================================================

config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.max_fps = 120

-- ============================================================
-- FONT + THEME
-- ============================================================

config.color_scheme = "Tokyo Night"

config.font = wezterm.font("JetBrainsMono Nerd Font", {
    weight = "Medium",
})

config.font_size = 22
config.term = "xterm-256color"

-- ============================================================
-- TMUX
-- ============================================================

local function find_cmd(cmd)
    local ok, handle = pcall(io.popen, 'command -v ' .. cmd .. ' 2>/dev/null')
    if not ok or handle == nil then
        return nil
    end
    local path = handle:read("*a") or ""
    handle:close()
    path = path:gsub("%s+$", "")
    if path == "" then
        return nil
    end
    return path
end

local tmux_path = find_cmd("tmux")
if tmux_path then
    config.default_prog = { tmux_path, "new-session", "-A", "-s", "main" }
else
    -- Fall back to the user's shell if tmux isn't available in PATH
    local shell = os.getenv("SHELL") or "/bin/sh"
    config.default_prog = { shell, "-l" }
    wezterm.log_info("tmux not found in PATH, falling back to shell: " .. shell)
end

local function tmux_binding(key)
    return wezterm.action.SendString("\x01" .. key)
end

-- ============================================================
-- KEYS
-- ============================================================

config.keys = {
    -- random background
    {
        key = "b", mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            local new_bg = choose_random_background()
            if new_bg then
                bg_image = new_bg
                window:set_config_overrides({
                    window_background_image = bg_image,
                })
                wezterm.log_info("New bg: " .. bg_image)
            else
                wezterm.log_error("Could not find bg image")
            end
        end),
    },
    -- brightness up
    {
        key = ">", mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            brightness = math.min(brightness + 0.01, 1.0)
            window:set_config_overrides({
                window_background_image_hsb = {
                    brightness = brightness,
                    hue = 1.0,
                    saturation = 0.8,
                },
                window_background_image = bg_image,
            })
        end),
    },
    -- brightness down
    {
        key = "<", mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            brightness = math.max(brightness - 0.01, 0.01)
            window:set_config_overrides({
                window_background_image_hsb = {
                    brightness = brightness,
                    hue = 1.0,
                    saturation = 0.8,
                },
                window_background_image = bg_image,
            })
        end),
    },
    -- open link
    { key = "L", mods = "CTRL|SHIFT", action = act.OpenLinkAtMouseCursor },
    -- music controls
    { key = "F6", action = wezterm.action_callback(play_random_music) },
    { key = "F7", action = wezterm.action_callback(stop_music) },
    { key = "F8", action = wezterm.action_callback(function() wezterm.background_child_process({ "pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%" }) end) },
    { key = "F9", action = wezterm.action_callback(function() wezterm.background_child_process({ "pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%" }) end) },
    { key = "F10", action = wezterm.action_callback(function() play_music(default_music) end) },
    -- tmux
    { key = "h", mods = "ALT", action = tmux_binding("h") },
    { key = "j", mods = "ALT", action = tmux_binding("j") },
    { key = "k", mods = "ALT", action = tmux_binding("k") },
    { key = "l", mods = "ALT", action = tmux_binding("l") },
}

-- ============================================================
-- CURSOR
-- ============================================================

config.default_cursor_style = "BlinkingUnderline"
config.cursor_thickness = 2

-- ============================================================
-- EVENTS
-- ============================================================

-- Do not perform side-effects on config load. Respect MODE and opt-in env vars.
wezterm.on("gui-startup", function()
    if MODE == "minimal" then
        wezterm.log_info("WezTerm started in minimal mode; skipping aesthetics and side-effects")
        return
    end
    if MODE == "normal" then
        wezterm.log_info("WezTerm started in normal mode; aesthetics are disabled by default")
        return
    end
    wezterm.log_info("WezTerm started in aesthetic mode; startup music is intentionally disabled")
end)

return config
