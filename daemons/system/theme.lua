local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gfilesystem = require("gears.filesystem")
local wibox = require("wibox")
local settings = require("services.settings")
local helpers = require("helpers")
local string = string
local pairs = pairs
local table = table
local capi = { screen = screen, client = client }

local theme = { }
local instance = nil


local function generate_colorscheme_from_wallpaper(self, wallpaper)
    awful.spawn.easy_async_with_shell("magick " .. wallpaper .. "" .. " -resize 25% -colors 16 -unique-colors txt:-", function(stdout)
        local colors = {}
        for line in stdout:gmatch("[^\r\n]+") do
            local hex = line:match("#(.*) s")
            if hex ~= nil then
                hex = "#" .. string.sub (hex, 1, 6)
                table.insert(colors, hex)
            end
        end

        if string.sub(colors[1], 2, 2) ~= "0" then
            colors[1] = helpers.color.darken(colors[1], 24)
        end
        colors[9] = helpers.color.nice_lighten(colors[1], 13)
        colors[9] = helpers.color.saturate_color(colors[9], 0.5)

        colors[8] = helpers.color.blend(colors[16], "#EEEEEE")
        colors[16] = helpers.color.nice_lighten(colors[8], 15)

        colors[2] = helpers.color.alter_brightness(colors[10], -0.2, 0.2)
        colors[3] = helpers.color.alter_brightness(colors[11], -0.2, 0.2)
        colors[4] = helpers.color.alter_brightness(colors[12], -0.2, 0.2)
        colors[5] = helpers.color.alter_brightness(colors[13], -0.2, 0.2)
        colors[6] = helpers.color.alter_brightness(colors[14], -0.2, 0.2)
        colors[7] = helpers.color.alter_brightness(colors[15], -0.2, 0.2)

        self:emit_signal("new_colorscheme", colors)
    end)
end

function theme:select_wallpaper(wallpaper_path)
    self._private.current_wallpaper = wallpaper_path
end

function theme:set_wallpaper(set_wallpaper, set_colorscheme)
    if set_wallpaper then
        settings:set_value("current_wallpaper", self._private.current_wallpaper)
        for s in capi.screen do
            capi.screen.emit_signal("request::wallpaper", s)
        end
    end
    if set_colorscheme == true then
        awful.spawn("wpg -ns " .. self._private.current_wallpaper, false)
    end
end

function theme:add_colorscheme()
    awful.spawn.easy_async("yad --file --multiple", function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            generate_colorscheme_from_wallpaper(self, line)
        end
    end)
end

function theme:select_colorscheme(colorscheme_path)
    self._private.current_colorscheme_path = colorscheme_path
    settings:set_value("current_colorscheme", self._private.current_colorscheme_path)

    helpers.filesystem.read_file(colorscheme_path, function(content)
        self._private.current_colorscheme = helpers.json.decode(content)
        awful.spawn.easy_async_with_shell("magick " .. self._private.current_colorscheme.wallpaper .. "" .. " -resize 25% -colors 16 -unique-colors txt:-", function(stdout)
            local colors = {}
            for line in stdout:gmatch("[^\r\n]+") do
                local hex = line:match("#(.*) s")
                if hex ~= nil then
                    hex = "#" .. string.sub (hex, 1, 6)
                    table.insert(colors, hex)
                end
            end

            if string.sub(colors[1], 2, 2) ~= "0" then
                colors[1] = helpers.color.darken(colors[1], 24)
            end
            colors[9] = helpers.color.nice_lighten(colors[1], 13)
            colors[9] = helpers.color.saturate_color(colors[9], 0.5)

            colors[8] = helpers.color.blend(colors[16], "#EEEEEE")
            colors[16] = helpers.color.nice_lighten(colors[8], 15)

            colors[2] = helpers.color.alter_brightness(colors[10], -0.2, 0.2)
            colors[3] = helpers.color.alter_brightness(colors[11], -0.2, 0.2)
            colors[4] = helpers.color.alter_brightness(colors[12], -0.2, 0.2)
            colors[5] = helpers.color.alter_brightness(colors[13], -0.2, 0.2)
            colors[6] = helpers.color.alter_brightness(colors[14], -0.2, 0.2)
            colors[7] = helpers.color.alter_brightness(colors[15], -0.2, 0.2)

            self:emit_signal("current_colorscheme", self._private.current_colorscheme_path, colors)
        end)
    end)
end

function theme:auto_adjust_colorscheme()
    awful.spawn.easy_async("wpg -A " .. self._private.current_colorscheme.wallpaper, function(stdout)
        helpers.filesystem.read_file(self._private.current_colorscheme_path, function(content)
            self._private.current_colorscheme = helpers.json.decode(content)
            self:emit_signal("current_colorscheme", self._private.current_colorscheme_path, self._private.current_colorscheme)
        end)
    end)
end

function theme:shuffle_colorscheme()
    awful.spawn.easy_async("wpg -z " .. self._private.current_colorscheme.wallpaper, function(stdout)
        helpers.filesystem.read_file(self._private.current_colorscheme_path, function(content)
            self._private.current_colorscheme = helpers.json.decode(content)
            self:emit_signal("current_colorscheme", self._private.current_colorscheme_path, self._private.current_colorscheme)
        end)
    end)
end

function theme:reset_colorscheme()
    awful.spawn.easy_async("wpg -R " .. self._private.current_colorscheme.wallpaper, function(stdout)
        helpers.filesystem.read_file(self._private.current_colorscheme_path, function(content)
            self._private.current_colorscheme = helpers.json.decode(content)
            self:emit_signal("current_colorscheme", self._private.current_colorscheme_path, self._private.current_colorscheme)
        end)
    end)
end

function theme:save_colorscheme()
    helpers.filesystem.save_file(
        self._private.current_colorscheme_path,
        helpers.json.encode(self._private.current_colorscheme, { indent = true })
    )
end

function theme:set_colorscheme(set_wallpaper, set_colorscheme)
    if set_wallpaper then
        settings:set_value("current_wallpaper", self._private.current_colorscheme.wallpaper)
        for s in capi.screen do
            capi.screen.emit_signal("request::wallpaper", s)
        end
    end
    if set_colorscheme then
        self:save_colorscheme()
        awful.spawn("wpg -ns " .. self._private.current_colorscheme.wallpaper, false)
    end
end

function theme:select_pywal_colorscheme(colorscheme_name)
    self._private.current_pywal_colorscheme_name = colorscheme_name
end

function theme:set_pywal_colorscheme()
    awful.spawn("wpg --theme " .. self._private.current_pywal_colorscheme_name, false)
end

function theme:edit_color(index)
    local color = self._private.current_colorscheme["colors"]["color" .. index - 1]
    local cmd = string.format([[yad --title='Pick A Color'  --width=500 --height=500 --color --init-color=%s
        --mode=hex --button=Cancel:1 --button=Select:0]], color)

    awful.spawn.easy_async(cmd, function(stdout, stderr)
        stdout = stdout:gsub("%s+", "")
        if stdout ~= "" and stdout ~= nil then
            self._private.current_colorscheme["colors"]["color" .. index - 1] = stdout
            self:emit_signal("current_colorscheme", self._private.current_colorscheme_path, self._private.current_colorscheme)
        end
    end)
end

function theme:get_wallpaper()
    return settings:get_value("current_wallpaper")
end

function theme:get_wallpapers()
    return self._private.wallpapers
end

function theme:get_colorschemes()
    return self._private.colorschemes
end

function theme:get_pywal_colorschemes(type)
    return self._private["pywal_colorscheme_" .. type]
end

local function set_wallpaper_for_screen(self, screen)
    awful.wallpaper
    {
        screen = screen,
        widget =
        {
            widget = wibox.widget.imagebox,
            resize = true,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = self._private.wallpaper
        }
    }
end

local function get_wallpapers(self)
    helpers.filesystem.scan("/home/kasper/Pictures/Wallpapers", function(result)
        self._private.wallpapers = {}
        -- local wpgtk_cmd = ""
        -- local low_res_cmd = ""

        for i, wallpaper_path in pairs(result) do
        --     local wallpaper_name = string.sub(
        --         wallpaper_path,
        --         helpers.string.find_last(wallpaper_path, "/") + 1, #wallpaper_path
        --     )
        --     local sample_path = gfilesystem.get_xdg_config_home() ..  "wpg/samples/" .. wallpaper_name .. "_wal_sample.png"
        --     if gfilesystem.file_readable(sample_path) == nil then
        --         sample_path = nil
        --     end

        --     local low_res_path = gfilesystem.get_cache_dir() .. "wallpapers_thumbnails/"
        --     if not gfilesystem.dir_readable(low_res_path) then
        --         gfilesystem.make_directories(low_res_path)
        --     end

        --     local low_res_wallpaper_path = low_res_path .. wallpaper_name
        --     if gfilesystem.file_readable(low_res_wallpaper_path) == nil then
        --         low_res_cmd = low_res_cmd .. string.format("convert -resize 320x320 -quality 25 %s %s &&", wallpaper_path, low_res_wallpaper_path)
        --     end

        --     local wpgtk_path = gfilesystem.get_xdg_config_home() .. "wpg/wallpapers/"
        --     local wpgtk_wallpaper_path = wpgtk_path .. wallpaper_name
        --     if gfilesystem.file_readable(wpgtk_wallpaper_path) == nil then
        --         wpgtk_cmd = wpgtk_cmd .. "wpg -a " .. wallpaper_path .. " &&"
        --     end

            table.insert(self._private.wallpapers, {
                name = wallpaper_path,
                wallpaper_path = wallpaper_path,
        --         low_res_wallpaper_path = low_res_wallpaper_path,
        --         sample_path = sample_path
            })
        --     if i == #result then
        --         self:emit_signal("wallpapers", self._private.wallpapers)
        --     end
        end

        -- awful.spawn.with_shell(wpgtk_cmd, false)
        -- awful.spawn.with_shell(low_res_cmd, false)
        self:emit_signal("wallpapers_updated", self._private.wallpapers)
    end, true)
end

local function get_colorschemes(self)
    helpers.filesystem.scan("/home/kasper/.config/wpg/schemes", function(result)
        self._private.colorschemes = {}
        for i, colorscheme_path in pairs(result) do
            helpers.filesystem.read_file(colorscheme_path, function(content)
                local colorscheme = helpers.json.decode(content)
                local low_res_path = gfilesystem.get_cache_dir() .. "wallpapers_thumbnails/"
                local wallpaper_name = string.sub(colorscheme.wallpaper,
                    helpers.string.find_last(colorscheme.wallpaper, "/") + 1, #colorscheme.wallpaper)

                table.insert(self._private.colorschemes, {
                    name = colorscheme_path,
                    colorscheme = colorscheme,
                    colorscheme_path = colorscheme_path,
                    wallpaper_name = wallpaper_name,
                    low_res_wallpaper_path = low_res_path .. wallpaper_name
                })

                if i == #result then
                    self:emit_signal("colorschemes", self._private.colorschemes)
                end
            end)
        end
    end, true)
end

local function get_pywal_colorschemes(self, type)
    helpers.filesystem.scan(string.format("/usr/lib/python3.9/site-packages/pywal/colorschemes/%s", type), function(result)
        self._private["pywal_colorscheme_" .. type] = {}
        for i, colorscheme_path in pairs(result or {}) do
            helpers.filesystem.read_file(colorscheme_path, function(content)
                local colorscheme_name = string.sub(colorscheme_path,
                    helpers.string.find_last(colorscheme_path, "/") + 1, #colorscheme_path)
                colorscheme_name = string.gsub(colorscheme_name, ".json", "")

                local colorscheme = helpers.json.decode(content)
                table.insert(self._private["pywal_colorscheme_" .. type], {
                    name = colorscheme_name,
                    colorscheme = colorscheme,
                    colorscheme_path = colorscheme_path,
                })

                if i == #result then
                    self:emit_signal(string.format("pywal_%s_colorschemes", type), self._private["pywal_colorscheme_" .. type])
                end
            end)
        end
    end, true)
end

local function update()
    local home = gfilesystem.get_xdg_config_home()

    -- Set lightdm glorious wallpaper
    awful.spawn("sudo cp " .. home .. "/wpg/.current /usr/share/backgrounds/gnome/wpgtk.jpg", false)

    -- Set refind wallpaper
    awful.spawn("sudo convert " .. home .. "/wpg/.current /boot/efi/EFI/refind/themes/rEFInd-sunset/background.png", false)

    -- Update applications themes
    -- Better discord doesn't like if the theme file is a link, so have to copy it each time
    --awful.spawn("cp " .. home .. "/wpg/templates/discord.theme.css " ..  .."/BetterDiscord/themes/wpgtk_discord.theme.css", false)
    awful.spawn("discocss", false)
    awful.spawn("telegram-palette-gen --wal", false)
    awful.spawn("spicetify update", false)
    awful.spawn("pywalfox update", false)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, theme, true)

    ret._private = {}
    ret._private.wallpaper = ret:get_wallpaper() or helpers.filesystem.get_awesome_config_dir("presentation/assets") .. "wallpaper.png"

    get_wallpapers(ret)

    -- awful.spawn.easy_async_with_shell(string.format([[ ps x | grep "inotifywait -e modify %s" | grep -v grep | awk '{print $1}' | xargs kill ]], "/home/kasper/.Xresources"), function()
    --     awful.spawn.with_line_callback(string.format([[ bash -c "while (inotifywait -e modify %s -qq) do echo; done" ]], "/home/kasper/Pictures/Wallpapers"), {stdout = function(line)
    --         -- get_wallpapers(ret)
    --     end})
    -- end)

    -- local current_wallpaper = settings:get_value("current_wallpaper")
    -- if current_wallpaper ~= nil then
    --     ret:select_wallpaper(current_wallpaper)
    -- end

    -- local current_colorscheme = settings:get_value("current_colorscheme")
    -- if current_colorscheme ~= nil then
    --     ret:select_colorscheme(current_colorscheme)
    -- end

    -- get_wallpapers(ret)
    -- get_colorschemes(ret)
    -- get_pywal_colorschemes(ret, "dark")
    -- get_pywal_colorschemes(ret, "light")

    -- awful.spawn.easy_async_with_shell(string.format([[ ps x | grep "inotifywait -e modify %s" | grep -v grep | awk '{print $1}' | xargs kill ]], "/home/kasper/.Xresources"), function()
    --     awful.spawn.with_line_callback(string.format([[ bash -c "while (inotifywait -e modify %s -qq) do echo; done" ]], "/home/kasper/Pictures/Wallpapers"), {stdout = function(line)
    --         get_wallpapers(ret)
    --     end})

    --     awful.spawn.with_line_callback(string.format([[ bash -c "while (inotifywait -e modify %s -qq) do echo; done" ]], "/home/kasper/.config/wpg/schemes"), {stdout = function(line)
    --         get_colorschemes(ret)
    --     end})

    --     awful.spawn.with_line_callback(string.format([[ bash -c "while (inotifywait -e modify %s -qq) do echo; done" ]], "/home/kasper/.Xresources"), {stdout = function(line)
    --         update()
    --         require("gears.timer") { timeout = 1, autostart = true, call_now = false, callback = function()
    --             awesome.restart()
    --         end }
    --     end})
    -- end)



    capi.screen.connect_signal("request::wallpaper", function(s)
        set_wallpaper_for_screen(ret, s)
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
