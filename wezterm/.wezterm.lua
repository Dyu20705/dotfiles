local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local io = require("io")
local os = require("os")

-- ── thư mục và biến toàn cục ─────────────────────────────────
local home = os.getenv("HOME")
local brightness = 0.03

-- nhạc
local music_folder = home .. "/dotfiles/wezterm/sd"
local default_music = music_folder .. "/bg.mp3"
local current_music_pid = nil

-- ảnh nền
local background_folder = home .. "/dotfiles/wezterm/bg"

-- ── tiện ích nhạc ────────────────────────────────────────────
local function pick_random_music(folder)
    local ok, files = pcall(wezterm.read_dir, folder)
    if not ok then return nil end
    local music_files = {}
    for _, file in ipairs(files) do
        if file:match("%.mp3$") or file:match("%.flac$") or file:match("%.wav$") or file:match("%.m4a$") then
            table.insert(music_files, folder .. "/" .. file)
        end
    end
    if #music_files > 0 then
        return music_files[math.random(#music_files)]
    end
    return nil
end

local function stop_music()
    if current_music_pid then
        os.execute("kill " .. current_music_pid .. " 2>/dev/null")
        current_music_pid = nil
    else
        os.execute("pkill mpv 2>/dev/null")
    end
end

local function play_music(file_path)
    stop_music()
    if not file_path then
        wezterm.log_error("Không tìm thấy file nhạc")
        return
    end
    local cmd = string.format('(mpv --no-video --really-quiet "%s" & echo $!) > /tmp/wezterm_mpv_pid', file_path)
    os.execute(cmd)
    local f = io.open("/tmp/wezterm_mpv_pid", "r")
    if f then
        current_music_pid = f:read("*line")
        f:close()
        wezterm.log_info("Phát: " .. file_path .. " (PID " .. current_music_pid .. ")")

        local track_name = file_path:match("([^/]+)$")
        os.execute(string.format('notify-send "Wezterm Music" "♪ %s"', track_name)) 
    else
        wezterm.log_info("Phát nền: " .. file_path)
    end
end

local function play_random_music()
    local music_file = pick_random_music(music_folder)
    if music_file then
        play_music(music_file)
    else
        wezterm.log_error("Thư mục nhạc trống: " .. music_folder)
    end
end

-- ── tiện ích ảnh nền ─────────────────────────────────────────
local function pick_random_background(folder)
    local ok, files = pcall(wezterm.read_dir, folder)
    if not ok then return nil end
    local images = {}
    for _, file in ipairs(files) do
        if file:match("%.jpg$") or file:match("%.png$") or file:match("%.jpeg$") then
            table.insert(images, folder .. "/" .. file)
        end
    end
    if #images > 0 then
        return images[math.random(#images)]
    end
    return nil
end

-- ảnh nền mặc định (ưu tiên random, fallback về bg.png)
local bg_image = pick_random_background(background_folder) or home .. "/dotfiles/wezterm/bg/bg.png"

config.window_background_image = bg_image
config.window_background_image_hsb = {
    brightness = brightness,
    hue = 1.0,
    saturation = 0.8,
}

-- ── slideshow ảnh nền mỗi 5 phút ─────────────────────────────
local function start_slideshow(window)
    if window._slideshow_timer then
        window._slideshow_timer:cancel()
    end

    local function schedule()
        window._slideshow_timer = wezterm.time.call_after(5 * 60, function()
            local new_bg = pick_random_background(background_folder)
            if new_bg then
                bg_image = new_bg
                window:set_config_overrides({
                    window_background_image = bg_image,
                })
            end
            schedule() -- lặp lại
        end)
    end
    schedule()
end

-- ── giao diện cửa sổ ─────────────────────────────────────────
config.window_background_opacity = 0.90
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.color_scheme = "Tokyo Night"
config.font = wezterm.font("Inconsolata Nerd Font Mono", { weight = "Medium", stretch = "Expanded" })
config.font_size = 22
config.window_decorations = "RESIZE"
config.enable_tab_bar = false

-- tự động vào tmux với session "main"
config.default_prog = { 'tmux', 'new-session', '-A', '-s', 'main' }

-- ── helper gửi lệnh tmux (prefix C-a) ────────────────────────
local function tmux_binding(key)
    -- \x01 tương đương với Ctrl-a, prefix của tmux
    return wezterm.action.SendString('\x01' .. key)
end

-- ── phím tắt tối ưu ──────────────────────────────────────────
config.keys = {
    -- copy/paste cơ bản
    { key = "[",        mods = "CTRL",        action = act.ActivateCopyMode },
    { key = "v",        mods = "CTRL|SHIFT",  action = act.PasteFrom("Clipboard") },

    -- chọn nhanh / mở link
    { key = "Enter",    mods = "SHIFT|CTRL",  action = act.QuickSelect },
    { key = "L",        mods = "CTRL|SHIFT",  action = act.OpenLinkAtMouseCursor },

    -- ảnh nền ngẫu nhiên + độ sáng
    { key = "b",        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            local new_bg = pick_random_background(background_folder)
            if new_bg then
                bg_image = new_bg
                window:set_config_overrides({
                    window_background_image = bg_image,
                })
            end
        end)
    },
    { key = ">",        mods = "CTRL|SHIFT",
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
        end)
    },
    { key = "<",        mods = "CTRL|SHIFT",
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
        end)
    },

    -- ứng dụng dev/research
    { key = "n",        mods = "CTRL|SHIFT",
        action = wezterm.action.SplitHorizontal {
            cwd = home .. "/Documents/git/scratch",
            args = { "nvim", "notes_" .. os.date("%y%m%d%H") .. ".md" },
        }
    },
    { key = "t",        mods = "CTRL|SHIFT",
        action = wezterm.action.SplitHorizontal {
            cwd = home .. "/Documents/git/scratch",
            args = { "nvim", "todo_" .. os.date("%y%m%d") .. ".md" },
        }
    },
    { key = "g",        mods = "CTRL|SHIFT",
        action = wezterm.action.SpawnCommandInNewTab {
            cwd = home,
            args = { "lazygit" },
        }
    },
    { key = "h",        mods = "CTRL|SHIFT",
        action = wezterm.action.SplitVertical {
            args = { "htop" },
        }
    },

    -- điều hướng tmux (C-a prefix)
    { key = "h",        mods = "ALT",          action = tmux_binding("h") },
    { key = "j",        mods = "ALT",          action = tmux_binding("j") },
    { key = "k",        mods = "ALT",          action = tmux_binding("k") },
    { key = "l",        mods = "ALT",          action = tmux_binding("l") },
    { key = "\\",       mods = "CTRL|SHIFT",   action = tmux_binding("\\") },
    { key = "-",        mods = "CTRL|SHIFT",   action = tmux_binding("-") },
    { key = "c",        mods = "CTRL|SHIFT",   action = tmux_binding("c") },
    { key = "r",        mods = "CTRL|SHIFT",   action = tmux_binding("r") },

    -- điều khiển nhạc (phím F)
    { key = "F6",
        action = wezterm.action_callback(play_random_music)
    },
    { key = "F7",
        action = wezterm.action_callback(stop_music)
    },
    { key = "F8",
        action = wezterm.action_callback(function() os.execute("pactl set-sink-volume @DEFAULT_SINK@ +5%") end)
    },
    { key = "F9",
        action = wezterm.action_callback(function() os.execute("pactl set-sink-volume @DEFAULT_SINK@ -5%") end)
    },
    { key = "F10",
        action = wezterm.action_callback(function() play_music(default_music) end)
    },
}

-- ── sự kiện khởi động ────────────────────────────────────────
wezterm.on("gui-startup", function()
    play_random_music()
    -- Khởi động slideshow cho cửa sổ đầu tiên (sẽ có ở window-created)
end)

wezterm.on("window-created", function(window)
    start_slideshow(window)
end)

wezterm.on("window-config-reloaded", function(window)
    start_slideshow(window)
end)

wezterm.on("window-close", function(window)
    if window._slideshow_timer then
        window._slideshow_timer:cancel()
    end
end)

-- ── các tùy chỉnh khác ───────────────────────────────────────
config.default_cursor_style = "BlinkingUnderline"
config.cursor_thickness = 2
config.max_fps = 120

return config
