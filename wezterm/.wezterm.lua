local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local io = require("io")
local os = require("os")
local math = require("math")

-- ============================================================
-- GLOBAL
-- ============================================================

local home = os.getenv("HOME")

local brightness = 0.03

-- Ảnh nền mặc định
local bg_image = home .. "/dotfiles/wezterm/bg/bg.png"

-- Thư mục ảnh ngẫu nhiên
local background_folder = home .. "/bg"

-- Nhạc
local music_folder = home .. "/dotfiles/wezterm/sd"
local default_music = music_folder .. "/bg.mp3"

-- ============================================================
-- RANDOM BACKGROUND
-- ============================================================

local function pick_random_background(folder)
    local handle = io.popen('ls "' .. folder .. '" 2>/dev/null')
    if not handle then return nil end
    local files = handle:read("*a")
    handle:close()

    local images = {}
    for file in string.gmatch(files, "[^\n]+") do
        if file:match("%.png$") or file:match("%.jpg$") or file:match("%.jpeg$") or file:match("%.webp$") then
            table.insert(images, file)
        end
    end
    if #images > 0 then
        return folder .. "/" .. images[math.random(#images)]
    end
    return nil
end

-- ============================================================
-- RANDOM MUSIC
-- ============================================================

local function pick_random_music(folder)
    local handle = io.popen('ls "' .. folder .. '" 2>/dev/null')
    if not handle then return nil end
    local files = handle:read("*a")
    handle:close()

    local music_files = {}
    for file in string.gmatch(files, "[^\n]+") do
        if file:match("%.mp3$") or file:match("%.flac$") or file:match("%.wav$") or file:match("%.m4a$") then
            table.insert(music_files, folder .. "/" .. file)
        end
    end
    if #music_files > 0 then
        return music_files[math.random(#music_files)]
    end
    return nil
end

-- ============================================================
-- MUSIC CONTROL
-- ============================================================

local function stop_music()
    -- Tắt mọi mpv (kể cả từ cửa sổ cũ)
    os.execute("pkill mpv 2>/dev/null")
    current_music_pid = nil
end

local function play_music(file_path)
    -- Dừng nhạc cũ trước khi phát mới
    stop_music()

    if not file_path then
        wezterm.log_error("Music file not found")
        return
    end

    local cmd = string.format(
        'sh -c \'mpv --no-video --loop --really-quiet "%s" >/dev/null 2>&1 & echo $! > /tmp/wezterm_mpv_pid\'',
        file_path
    )
    os.execute(cmd)

    local f = io.open("/tmp/wezterm_mpv_pid", "r")
    local current_music_pid = nil
    if f then
        current_music_pid = f:read("*line")
        f:close()
    end

    local track_name = file_path:match("([^/]+)$")
    wezterm.log_info("Playing: " .. track_name)
    os.execute('notify-send "WezTerm Music" "♪ ' .. track_name .. '"')
end

local function play_random_music()
    local music = pick_random_music(music_folder)
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

-- config.window_background_image_hsb = {
--     brightness = brightness,
--     hue = 1.0,
--     saturation = 0.8,
-- }

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

config.default_prog = { "tmux", "new-session", "-A", "-s", "main" }

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
            local new_bg = pick_random_background(background_folder)
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
    { key = "F8", action = wezterm.action_callback(function() os.execute("pactl set-sink-volume @DEFAULT_SINK@ +5%") end) },
    { key = "F9", action = wezterm.action_callback(function() os.execute("pactl set-sink-volume @DEFAULT_SINK@ -5%") end) },
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

wezterm.on("gui-startup", function()
    -- Phát nhạc khi GUI khởi động (lan dau tien)
    play_random_music()
end)

wezterm.on("window-close", function()
    -- Dừng nhạc khi tất cả cửa sổ đóng (không còn GUI)
    -- Nhưng vì pkill đã được gọi, nên chỉ cần dừng nếu muốn
    -- Có thể bỏ trống nếu không muốn tắt nhạc khi đóng 1 cửa sổ
end)

return config
